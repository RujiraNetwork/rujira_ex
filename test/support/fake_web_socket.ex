defmodule Rujira.Test.FakeWebSocket do
  @moduledoc """
  A local websocket server standing in for a CometBFT node in
  `Rujira.Node.Subscription` tests: RFC 6455 over `:gen_tcp`, one client at a
  time, every client frame reported to the owning test process.

  Messages to the owner:

    * `{:fake_ws, :connected}` - a client finished the handshake
    * `{:fake_ws, :subscribe, id, query}` - a JSON-RPC `subscribe` request
    * `{:fake_ws, :text, text}` - any other text frame
    * `{:fake_ws, :ping}` / `{:fake_ws, :pong}` - control frames
    * `{:fake_ws, :closed}` - the client socket closed

  Options:

    * `:ack` - answer every `subscribe` with an empty result (default `true`)
    * `:pong` - answer pings (default `true`)
    * `:handshake` - `:ok` (default), `{:status, code}` to refuse the upgrade,
      or `:silent` to accept the TCP connection and never answer
  """

  use GenServer

  @guid "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

  # --- API ---

  @spec start(keyword()) :: {:ok, pid(), String.t()}
  def start(opts \\ []) do
    {:ok, pid} = GenServer.start_link(__MODULE__, Keyword.put_new(opts, :owner, self()))
    {:ok, pid, "ws://127.0.0.1:#{GenServer.call(pid, :port)}/websocket"}
  end

  @doc "Sends a text frame to the connected client."
  @spec send_text(pid(), String.t()) :: :ok
  def send_text(server, text), do: GenServer.call(server, {:send, 0x1, text})

  @doc "Sends a raw frame with `opcode` to the connected client."
  @spec send_frame(pid(), non_neg_integer(), binary()) :: :ok
  def send_frame(server, opcode, payload), do: GenServer.call(server, {:send, opcode, payload})

  @doc "Closes the connected client's socket without a close frame."
  @spec drop(pid()) :: :ok
  def drop(server), do: GenServer.call(server, :drop)

  @doc "How many clients completed the handshake so far."
  @spec connections(pid()) :: non_neg_integer()
  def connections(server), do: GenServer.call(server, :connections)

  @doc "A NewBlockHeader event for `height` under subscription `id`, shaped as mainnet sends it."
  @spec new_block(term(), pos_integer() | String.t()) :: String.t()
  def new_block(id, height) do
    "test/fixtures/websocket/new_block_header.json"
    |> File.read!()
    |> JSON.decode!()
    |> Map.put("id", id)
    |> put_in(["result", "data", "value", "header", "height"], to_string(height))
    |> JSON.encode!()
  end

  # --- Server ---

  @impl true
  def init(opts) do
    {:ok, listen} =
      :gen_tcp.listen(0, [
        :binary,
        packet: :raw,
        active: false,
        reuseaddr: true,
        ip: {127, 0, 0, 1}
      ])

    server = self()
    acceptor = spawn_link(fn -> accept_loop(listen, server) end)

    {:ok,
     %{
       listen: listen,
       acceptor: acceptor,
       owner: Keyword.fetch!(opts, :owner),
       ack: Keyword.get(opts, :ack, true),
       pong: Keyword.get(opts, :pong, true),
       handshake: Keyword.get(opts, :handshake, :ok),
       socket: nil,
       buffer: "",
       upgraded: false,
       connections: 0
     }}
  end

  @impl true
  def handle_call(:port, _from, state) do
    {:ok, port} = :inet.port(state.listen)
    {:reply, port, state}
  end

  def handle_call(:connections, _from, state), do: {:reply, state.connections, state}

  def handle_call({:send, opcode, payload}, _from, %{socket: socket} = state)
      when socket != nil do
    :ok = :gen_tcp.send(socket, encode(opcode, payload))
    {:reply, :ok, state}
  end

  def handle_call(:drop, _from, state) do
    {:reply, :ok, close(state)}
  end

  @impl true
  def handle_info({:accepted, socket}, state) do
    state = close(state)
    :ok = :inet.setopts(socket, active: true)
    {:noreply, %{state | socket: socket, buffer: "", upgraded: false}}
  end

  def handle_info({:tcp, socket, data}, %{socket: socket} = state) do
    {:noreply, process(%{state | buffer: state.buffer <> data})}
  end

  def handle_info({:tcp_closed, socket}, %{socket: socket} = state) do
    send(state.owner, {:fake_ws, :closed})
    {:noreply, %{state | socket: nil}}
  end

  def handle_info(_message, state), do: {:noreply, state}

  # --- Private ---

  defp accept_loop(listen, server) do
    case :gen_tcp.accept(listen) do
      {:ok, socket} ->
        :ok = :gen_tcp.controlling_process(socket, server)
        send(server, {:accepted, socket})
        accept_loop(listen, server)

      {:error, _} ->
        :ok
    end
  end

  defp close(%{socket: nil} = state), do: state

  defp close(%{socket: socket} = state) do
    :gen_tcp.close(socket)
    %{state | socket: nil, buffer: ""}
  end

  defp process(%{upgraded: false, handshake: :silent} = state), do: state

  defp process(%{upgraded: false, buffer: buffer} = state) do
    case :binary.split(buffer, "\r\n\r\n") do
      [head, rest] -> handshake(state, head, rest)
      [_] -> state
    end
  end

  defp process(%{upgraded: true, buffer: buffer} = state) do
    case decode(buffer) do
      {:ok, opcode, payload, rest} ->
        process(handle_frame(%{state | buffer: rest}, opcode, payload))

      :more ->
        state
    end
  end

  defp handshake(%{handshake: {:status, code}} = state, _head, _rest) do
    :gen_tcp.send(state.socket, "HTTP/1.1 #{code} Nope\r\ncontent-length: 0\r\n\r\n")
    state
  end

  defp handshake(state, head, rest) do
    [key] =
      for line <- String.split(head, "\r\n"),
          [name, value] <- [String.split(line, ":", parts: 2)],
          String.downcase(name) == "sec-websocket-key",
          do: String.trim(value)

    accept = :crypto.hash(:sha, key <> @guid) |> Base.encode64()

    :ok =
      :gen_tcp.send(
        state.socket,
        "HTTP/1.1 101 Switching Protocols\r\nupgrade: websocket\r\nconnection: Upgrade\r\n" <>
          "sec-websocket-accept: #{accept}\r\n\r\n"
      )

    send(state.owner, {:fake_ws, :connected})
    process(%{state | upgraded: true, buffer: rest, connections: state.connections + 1})
  end

  defp handle_frame(state, 0x1, text) do
    case JSON.decode(text) do
      {:ok, %{"method" => "subscribe", "id" => id, "params" => %{"query" => query}}} ->
        send(state.owner, {:fake_ws, :subscribe, id, query})

        if state.ack,
          do: send_raw(state, 0x1, JSON.encode!(%{jsonrpc: "2.0", id: id, result: %{}}))

        state

      _ ->
        send(state.owner, {:fake_ws, :text, text})
        state
    end
  end

  defp handle_frame(state, 0x9, payload) do
    send(state.owner, {:fake_ws, :ping})
    if state.pong, do: send_raw(state, 0xA, payload)
    state
  end

  defp handle_frame(state, 0xA, _payload) do
    send(state.owner, {:fake_ws, :pong})
    state
  end

  defp handle_frame(state, 0x8, _payload), do: close(state)
  defp handle_frame(state, _opcode, _payload), do: state

  defp send_raw(%{socket: socket}, opcode, payload),
    do: :gen_tcp.send(socket, encode(opcode, payload))

  # Server frames are never masked.
  defp encode(opcode, payload) do
    size = byte_size(payload)

    length =
      cond do
        size < 126 -> <<size::8>>
        size < 65_536 -> <<126::8, size::16>>
        true -> <<127::8, size::64>>
      end

    <<1::1, 0::3, opcode::4>> <> length <> payload
  end

  # Client frames are always masked.
  defp decode(
         <<_fin::1, _rsv::3, opcode::4, 1::1, 126::7, size::16, mask::binary-4, rest::binary>>
       ),
       do: unmask(opcode, size, mask, rest)

  defp decode(
         <<_fin::1, _rsv::3, opcode::4, 1::1, 127::7, size::64, mask::binary-4, rest::binary>>
       ),
       do: unmask(opcode, size, mask, rest)

  defp decode(<<_fin::1, _rsv::3, opcode::4, 1::1, size::7, mask::binary-4, rest::binary>>)
       when size < 126,
       do: unmask(opcode, size, mask, rest)

  defp decode(_buffer), do: :more

  defp unmask(opcode, size, mask, rest) when byte_size(rest) >= size do
    <<masked::binary-size(^size), rest::binary>> = rest
    {:ok, opcode, :crypto.exor(masked, mask_stream(mask, size)), rest}
  end

  defp unmask(_opcode, _size, _mask, _rest), do: :more

  defp mask_stream(mask, size) do
    mask |> :binary.copy(div(size, 4) + 1) |> binary_part(0, size)
  end
end
