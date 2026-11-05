if Code.ensure_loaded?(Mint.WebSocket) do
  defmodule Rujira.Node.Subscription.Connection do
    @moduledoc """
    The websocket connection behind `Rujira.Node.Subscription`: connects,
    subscribes to new block headers, sends each height to the subscribers in
    its `Registry`, and reconnects with backoff whenever any of that fails.

    Started by `Rujira.Node.Subscription`; not meant to be started on its own.
    Compiled only when the optional dependency `:mint_web_socket` is present.
    """

    use GenServer

    alias Rujira.Logger
    alias Rujira.Node.Subscription.Backoff
    alias Rujira.Node.Subscription.Endpoint
    alias Rujira.Node.Subscription.Message
    alias Rujira.Node.Subscription.Telemetry

    @defaults [
      ping_interval: 15_000,
      connect_timeout: 10_000,
      backoff_base: 500,
      backoff_max: 30_000
    ]

    # --- Struct ---

    defstruct endpoint: nil,
              registry: nil,
              settings: %{},
              status: :disconnected,
              conn: nil,
              ref: nil,
              websocket: nil,
              upgrade_status: nil,
              upgrade_headers: [],
              attempt: 0,
              gen: 0,
              started_at: nil,
              awaiting_pong: false,
              last_height: 0

    @type status :: :disconnected | :upgrading | :subscribing | :subscribed

    @type t :: %__MODULE__{
            endpoint: Endpoint.t() | nil,
            registry: atom() | nil,
            settings: map(),
            status: status(),
            conn: Mint.HTTP.t() | nil,
            ref: Mint.Types.request_ref() | nil,
            websocket: Mint.WebSocket.t() | nil,
            upgrade_status: non_neg_integer() | nil,
            upgrade_headers: Mint.Types.headers(),
            attempt: non_neg_integer(),
            gen: non_neg_integer(),
            started_at: integer() | nil,
            awaiting_pong: boolean(),
            last_height: non_neg_integer()
          }

    # --- Construction ---

    @doc false
    @spec start_link(keyword()) :: GenServer.on_start()
    def start_link(opts), do: GenServer.start_link(__MODULE__, opts)

    @impl true
    def init(opts) do
      {:ok, endpoint} = Endpoint.new(Keyword.fetch!(opts, :url))

      settings =
        @defaults |> Keyword.merge(Keyword.take(opts, Keyword.keys(@defaults))) |> Map.new()

      state = %__MODULE__{
        endpoint: endpoint,
        registry: Keyword.fetch!(opts, :registry),
        settings: settings
      }

      {:ok, state, {:continue, :connect}}
    end

    # --- Callbacks ---

    @impl true
    def handle_continue(:connect, state), do: {:noreply, connect(state)}

    @impl true
    def handle_info({:connect, gen}, %__MODULE__{gen: gen, status: :disconnected} = state),
      do: {:noreply, connect(state)}

    def handle_info({:connect_timeout, gen}, %__MODULE__{gen: gen, status: status} = state)
        when status in [:upgrading, :subscribing],
        do: {:noreply, fail(state, :connect_timeout)}

    def handle_info({:ping, gen}, %__MODULE__{gen: gen, status: :subscribed} = state),
      do: {:noreply, ping(state)}

    # A timer of an earlier connection.
    def handle_info({tag, _gen}, state) when tag in [:connect, :connect_timeout, :ping],
      do: {:noreply, state}

    def handle_info(message, %__MODULE__{conn: nil} = state) do
      Logger.debug(__MODULE__, "ignored #{inspect(message)} while disconnected")
      {:noreply, state}
    end

    def handle_info(message, %__MODULE__{conn: conn} = state) do
      case Mint.WebSocket.stream(conn, message) do
        {:ok, conn, responses} ->
          {:noreply, handle_responses(%{state | conn: conn}, responses)}

        {:error, conn, reason, _responses} ->
          {:noreply, fail(%{state | conn: conn}, reason)}

        :unknown ->
          {:noreply, state}
      end
    rescue
      # Whatever the node sends must not restart this process in a loop: a
      # supervisor that gives up would take `Rujira.Supervisor` down with it.
      exception -> {:noreply, fail(state, {:exception, exception})}
    end

    @impl true
    def terminate(_reason, state), do: close(state)

    # --- Connection ---

    defp connect(%__MODULE__{endpoint: endpoint, settings: settings} = state) do
      gen = state.gen + 1
      started_at = System.monotonic_time()
      Process.send_after(self(), {:connect_timeout, gen}, settings.connect_timeout)

      state = %{state | gen: gen, started_at: started_at, awaiting_pong: false}

      with {:ok, conn} <-
             Mint.HTTP.connect(Endpoint.http_scheme(endpoint), endpoint.host, endpoint.port,
               protocols: [:http1],
               transport_opts: [timeout: settings.connect_timeout]
             ),
           {:ok, conn, ref} <- upgrade(conn, endpoint) do
        %{
          state
          | conn: conn,
            ref: ref,
            status: :upgrading,
            upgrade_status: nil,
            upgrade_headers: []
        }
      else
        {:error, reason} -> fail(state, reason)
        {:error, conn, reason} -> fail(%{state | conn: conn}, reason)
      end
    end

    defp upgrade(conn, %Endpoint{scheme: scheme, path: path}),
      do: Mint.WebSocket.upgrade(scheme, conn, path, [])

    # Dialyzer (OTP 29, mint_web_socket 1.0.6) concludes that
    # `Mint.WebSocket.new/4` never returns `{:ok, conn, websocket}`, which a
    # bare call of it outside this module reproduces: a false positive in the
    # dependency. The tests drive both branches.
    @dialyzer {:nowarn_function, open: 1, subscribe: 1}
    defp open(%__MODULE__{conn: conn, ref: ref} = state) do
      case Mint.WebSocket.new(conn, ref, state.upgrade_status, state.upgrade_headers) do
        {:ok, conn, websocket} ->
          subscribe(%{state | conn: conn, websocket: websocket, status: :subscribing})

        {:error, conn, reason} ->
          fail(%{state | conn: conn}, reason)
      end
    end

    defp handle_responses(state, responses), do: Enum.reduce(responses, state, &handle_response/2)

    # Once failed, the rest of a batch belongs to a closed connection.
    defp handle_response(_response, %__MODULE__{conn: nil} = state), do: state

    defp handle_response({:status, ref, status}, %__MODULE__{ref: ref} = state),
      do: %{state | upgrade_status: status}

    defp handle_response({:headers, ref, headers}, %__MODULE__{ref: ref} = state),
      do: %{state | upgrade_headers: state.upgrade_headers ++ headers}

    defp handle_response({:done, ref}, %__MODULE__{ref: ref, status: :upgrading} = state),
      do: open(state)

    defp handle_response({:data, ref, data}, %__MODULE__{ref: ref, websocket: ws} = state)
         when ws != nil do
      case Mint.WebSocket.decode(ws, data) do
        {:ok, ws, frames} -> Enum.reduce(frames, %{state | websocket: ws}, &handle_frame/2)
        {:error, ws, reason} -> fail(%{state | websocket: ws}, reason)
      end
    end

    defp handle_response({:error, ref, reason}, %__MODULE__{ref: ref} = state),
      do: fail(state, reason)

    defp handle_response(_response, state), do: state

    # --- Frames ---

    defp handle_frame(_frame, %__MODULE__{conn: nil} = state), do: state

    defp handle_frame({:text, text}, state) do
      case Message.parse(text) do
        {:ok, message} -> handle_message(message, state)
        {:error, reason} -> invalid_frame(state, reason)
      end
    end

    defp handle_frame({:ping, data}, state), do: send_frame(state, {:pong, data})
    defp handle_frame({:pong, _data}, state), do: %{state | awaiting_pong: false}
    defp handle_frame({:close, code, reason}, state), do: fail(state, {:closed, code, reason})
    defp handle_frame({:binary, _data}, state), do: invalid_frame(state, :binary_frame)
    defp handle_frame({:error, reason}, state), do: invalid_frame(state, reason)

    defp handle_message({:subscribed, gen}, %__MODULE__{gen: gen, status: :subscribing} = state) do
      Telemetry.connect(state.endpoint.url, state.attempt, state.started_at)
      Logger.info(__MODULE__, "subscribed to new blocks at #{host(state)}")
      schedule_ping(state)
      %{state | status: :subscribed, attempt: 0}
    end

    defp handle_message({:new_block, gen, height}, %__MODULE__{gen: gen} = state)
         when height > state.last_height do
      subscribers = Registry.lookup(state.registry, :new_block)
      Enum.each(subscribers, fn {pid, _} -> send(pid, {:rujira_new_block, height}) end)
      Telemetry.new_block(state.endpoint.url, height, length(subscribers))
      %{state | last_height: height}
    end

    defp handle_message({:new_block, gen, _height}, %__MODULE__{gen: gen} = state), do: state

    defp handle_message({:rpc_error, id, error}, %__MODULE__{gen: gen} = state)
         when id in [gen, nil],
         do: fail(state, {:rpc_error, error})

    defp handle_message(message, state), do: invalid_frame(state, {:unexpected, message})

    defp invalid_frame(state, reason) do
      Telemetry.invalid_frame(state.endpoint.url, reason)
      Logger.debug(__MODULE__, "skipped a frame from #{host(state)}: #{inspect(reason)}")
      state
    end

    defp subscribe(state), do: send_frame(state, {:text, Message.subscribe(state.gen)})

    defp ping(%__MODULE__{awaiting_pong: true} = state), do: fail(state, :ping_timeout)

    defp ping(state) do
      state = send_frame(%{state | awaiting_pong: true}, {:ping, ""})
      if state.conn, do: schedule_ping(state)
      state
    end

    defp schedule_ping(%__MODULE__{gen: gen, settings: settings}),
      do: Process.send_after(self(), {:ping, gen}, settings.ping_interval)

    defp send_frame(%__MODULE__{conn: conn, ref: ref, websocket: ws} = state, frame) do
      case Mint.WebSocket.encode(ws, frame) do
        {:ok, ws, data} -> stream_frame(%{state | websocket: ws}, conn, ref, data)
        {:error, ws, reason} -> fail(%{state | websocket: ws}, reason)
      end
    end

    defp stream_frame(state, conn, ref, data) do
      case Mint.WebSocket.stream_request_body(conn, ref, data) do
        {:ok, conn} -> %{state | conn: conn}
        {:error, conn, reason} -> fail(%{state | conn: conn}, reason)
      end
    end

    # --- Failure ---

    defp fail(%__MODULE__{settings: settings} = state, reason) do
      close(state)
      delay = Backoff.delay(state.attempt, settings.backoff_base, settings.backoff_max)
      Telemetry.disconnect(state.endpoint.url, reason, state.attempt + 1, delay)
      log_failure(state, reason, delay)
      Process.send_after(self(), {:connect, state.gen}, delay)

      %{
        state
        | status: :disconnected,
          conn: nil,
          ref: nil,
          websocket: nil,
          awaiting_pong: false,
          attempt: state.attempt + 1
      }
    end

    defp log_failure(%__MODULE__{status: status, attempt: attempt} = state, reason, delay)
         when status == :subscribed or attempt == 0 do
      Logger.warning(
        __MODULE__,
        "no subscription at #{host(state)}: #{inspect(reason)}; reconnecting in #{delay} ms"
      )
    end

    defp log_failure(state, reason, delay) do
      Logger.debug(
        __MODULE__,
        "attempt #{state.attempt + 1} at #{host(state)} failed: #{inspect(reason)}; retrying in #{delay} ms"
      )
    end

    defp close(%__MODULE__{conn: nil}), do: :ok

    defp close(%__MODULE__{conn: conn}) do
      Mint.HTTP.close(conn)
      :ok
    end

    defp host(%__MODULE__{endpoint: %Endpoint{host: host, port: port}}), do: "#{host}:#{port}"
  end
end
