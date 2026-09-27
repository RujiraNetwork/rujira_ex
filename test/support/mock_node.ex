defmodule Rujira.Test.MockNode do
  @moduledoc """
  Mock node implementation for tests.

  By default every query is unconfigured. A test can script a query with
  `expect/1`, which receives a decoded query map and returns whatever
  `Rujira.Node.query/3` should hand back:

      MockNode.expect(fn
        %{"ranges" => %{"dynamic" => _}} -> {:error, %GRPC.RPCError{...}}
        %{"ranges" => _} -> MockNode.ok(%{"ranges" => []})
      end)

  For a `QuerySmartContractStateRequest`, the script receives the decoded
  smart-contract query. For any other request struct (e.g. gRPC query
  requests like `QueryBalanceRequest`), the script receives the request
  struct itself.

  The script lives in the process dictionary, so it is per-test and safe under
  `async: true`. A query issued from a `Task` started by the test - a fan-out
  such as `Rujira.Fin.Order.list_all_pairs/2` - finds the script through
  `$callers`, so those legs are scriptable too.

  Every query also sends `{:mock_node, request, opts}` to the calling process,
  so a test can assert on the opts a height-aware caller passed down.
  """
  @behaviour Rujira.Node

  alias Cosmwasm.Wasm.V1.QuerySmartContractStateRequest

  @key :mock_node_script

  @doc "Scripts queries for the current process."
  @spec expect((map() | struct() -> {:ok, term()} | {:error, term()})) :: :ok
  def expect(fun) when is_function(fun, 1) do
    Process.put(@key, fun)
    :ok
  end

  @doc "Wraps a term as the node's raw JSON response envelope."
  @spec ok(term()) :: {:ok, %{data: binary()}}
  def ok(payload), do: {:ok, %{data: JSON.encode!(payload)}}

  @impl true
  def query(fun, request, opts \\ [])

  def query(_fun, %QuerySmartContractStateRequest{query_data: query_data} = request, opts) do
    send(self(), {:mock_node, request, opts})
    respond(script(), JSON.decode!(query_data), opts)
  end

  def query(_fun, request, opts) do
    send(self(), {:mock_node, request, opts})
    respond(script(), request, opts)
  end

  defp script, do: Process.get(@key) || Enum.find_value(callers(), &caller_script/1)

  defp callers, do: Process.get(:"$callers", [])

  defp caller_script(pid) do
    case Process.info(pid, :dictionary) do
      {:dictionary, dictionary} -> Keyword.get(dictionary, @key)
      nil -> nil
    end
  end

  defp respond(nil, _decoded, _opts), do: {:error, :not_configured}

  defp respond(script, decoded, opts) do
    case script.(decoded) do
      {:ok, reply} = result ->
        if opts[:return_headers] do
          height = get_in(opts, [:metadata, "x-cosmos-block-height"])
          {:ok, reply, %{headers: %{"x-cosmos-block-height" => height}, trailers: %{}}}
        else
          result
        end

      result ->
        result
    end
  end
end
