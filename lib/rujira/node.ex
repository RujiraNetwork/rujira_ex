defmodule Rujira.Node do
  @moduledoc """
  Behaviour and configurable delegator for chain node queries.

  Consumers configure the implementation via application env:

      config :rujira_ex, node: MyApp.NodeImpl

  The implementation must export `query/3`.

  ## Options

  `opts` is a keyword list forwarded to the configured implementation, with two
  reserved keys:

    * `:fan_out` - the concurrent fan-out policy (see `Rujira.Enum`). It is
      dropped before the impl is called: it governs this library's own
      `Task.async_stream` runs, never the node call, whose own `timeout:` is
      the gRPC deadline and stays the impl's business.
    * `:height` - when present, it is popped from `opts` before the impl is
      called - the key itself never reaches the impl. `height: nil` is treated
      as absent. Any other value must be an integer in
      `1..9_223_372_036_854_775_807`, otherwise `query/3` returns
      `{:error, :invalid_height}` without calling the impl.

  ## Height semantics

  When a valid `:height` is given:

    * `fun` must have arity 3 - an arity-2 stub cannot carry the metadata
      needed to request a historical height, so `query/3` returns
      `{:error, :height_not_supported}` without calling the impl.
    * The remaining opts are merged with `metadata: %{"x-cosmos-block-height"
      => Integer.to_string(height)}` (existing `:metadata` keys are kept) and
      `return_headers: true`, and the impl is called with the merged opts.
    * The impl's reply is verified against the requested height before being
      handed back - a mismatched or missing height is never silently
      returned as data:
      * `{:ok, reply, %{headers: headers}}` - if `headers` (a map or a list
        of `{k, v}` pairs) carries the requested height, `{:ok, reply}`.
        Otherwise `{:error, {:height_mismatch, height, returned}}`, where
        `returned` is the parsed height or `nil`.
      * `{:ok, reply}`, or `{:ok, reply, meta}` whose `meta` carries no
        `:headers` - the impl dropped the headers, so this cannot be
        verified: `{:error, {:height_mismatch, height, nil}}`.
      * `{:error, %GRPC.RPCError{}}` matching `height_unavailable?/1` -
        `{:error, {:height_unavailable, height}}`.
      * Any other error is returned unchanged.

  Without `:height`, `opts` is forwarded unchanged and the impl's result is
  returned unchanged - today's behaviour.

  ## Implementation contract

  A configured impl's `query/3` must forward `opts` unchanged to arity-3
  `fun`s (so `:metadata` and `:return_headers` reach the underlying gRPC
  call), and return the stub's result unchanged.
  """

  alias Rujira.Math

  @typedoc """
  An error returned by the chain node.

  grpc 1.0 moved `GRPC.RPCError` into the `grpc_core` package and dropped its
  `t/0`, as it did for `GRPC.Channel`. Both structs are therefore named directly
  and shared from this module rather than referenced as `GRPC.RPCError.t()`
  across the codebase.
  """
  @type rpc_error :: %GRPC.RPCError{}

  @typedoc "An open connection to a chain node."
  @type channel :: %GRPC.Channel{}

  @type query_fun ::
          (channel(), term() -> {:ok, term()} | {:error, rpc_error() | term()})

  @type query_fun3 ::
          (channel(), term(), keyword() ->
             {:ok, term()} | {:error, rpc_error() | term()})

  @typedoc "Options accepted by `query/3`. See the moduledoc for `:height` semantics."
  @type opts :: keyword()

  @callback query(query_fun() | query_fun3(), term(), keyword()) ::
              {:ok, term()} | {:error, term()}

  @height_unavailable_patterns [
    "cannot query with height in the future",
    "failed to load state at height",
    "must be less than or equal to the current blockchain height",
    "is not available, lowest height is",
    "could not find results for height"
  ]

  @block_height_header "x-cosmos-block-height"

  # --- Queries ---

  @spec query(query_fun() | query_fun3(), term(), opts()) :: {:ok, term()} | {:error, term()}
  def query(fun, request, opts \\ [])

  def query(fun, request, opts) do
    case opts |> Keyword.delete(:fan_out) |> Keyword.pop(:height) do
      {nil, rest} ->
        impl().query(fun, request, rest)

      {height, rest} ->
        with {:ok, height} <- validate_height(height) do
          do_height_query(fun, request, rest, height)
        end
    end
  end

  @doc "Whether `term` is a chain-node error meaning the requested height is unavailable."
  @spec height_unavailable?(term()) :: boolean()
  def height_unavailable?(%GRPC.RPCError{message: message}) when is_binary(message) do
    downcased = String.downcase(message)
    Enum.any?(@height_unavailable_patterns, &String.contains?(downcased, &1))
  end

  def height_unavailable?(_), do: false

  @doc """
  Runs `fetch` when `opts` requests a historical height, `cached` otherwise.

  The one place the `:height` check lives, so a memoized query can keep its
  cached path for live reads and take an uncached one for a height read - a
  height read is never cached.
  """
  @spec at_height(opts(), (-> result), (-> result)) :: result when result: var
  def at_height(opts, fetch, cached), do: dispatch(Keyword.get(opts, :height), fetch, cached)

  # --- Private ---

  defp dispatch(nil, _fetch, cached), do: cached.()
  defp dispatch(_height, fetch, _cached), do: fetch.()

  defp do_height_query(fun, _request, _opts, _height) when is_function(fun, 2) do
    {:error, :height_not_supported}
  end

  defp do_height_query(fun, request, opts, height) do
    metadata =
      opts
      |> Keyword.get(:metadata, %{})
      |> Map.put(@block_height_header, Integer.to_string(height))

    opts =
      opts
      |> Keyword.put(:metadata, metadata)
      |> Keyword.put(:return_headers, true)

    fun
    |> impl().query(request, opts)
    |> handle_height_result(height)
  end

  defp handle_height_result({:ok, reply, %{headers: headers}}, height) do
    returned = header_height(headers)

    if returned == height do
      {:ok, reply}
    else
      {:error, {:height_mismatch, height, returned}}
    end
  end

  defp handle_height_result({:ok, _reply, _meta}, height) do
    {:error, {:height_mismatch, height, nil}}
  end

  defp handle_height_result({:ok, _reply}, height) do
    {:error, {:height_mismatch, height, nil}}
  end

  defp handle_height_result({:error, error}, height) do
    if height_unavailable?(error) do
      {:error, {:height_unavailable, height}}
    else
      {:error, error}
    end
  end

  defp header_height(headers) when is_map(headers) do
    headers
    |> Map.get(@block_height_header)
    |> parse_header_height()
  end

  defp header_height(headers) when is_list(headers) do
    headers
    |> Enum.find_value(fn {k, v} -> if k == @block_height_header, do: v end)
    |> parse_header_height()
  end

  defp header_height(_headers), do: nil

  defp parse_header_height(value) do
    case Math.to_integer(value) do
      {:ok, height} -> height
      {:error, _} -> nil
    end
  end

  defp validate_height(height)
       when is_integer(height) and height >= 1 and height <= 9_223_372_036_854_775_807 do
    {:ok, height}
  end

  defp validate_height(_height), do: {:error, :invalid_height}

  defp impl do
    Application.get_env(:rujira_ex, :node) ||
      raise "No :node implementation configured for :rujira_ex. " <>
              "Set `config :rujira_ex, node: YourNodeModule`"
  end
end
