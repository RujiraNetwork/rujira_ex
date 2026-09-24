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
  `async: true`.
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

  def query(_fun, %QuerySmartContractStateRequest{query_data: query_data}, _opts) do
    respond(Process.get(@key), JSON.decode!(query_data))
  end

  def query(_fun, request, _opts), do: respond(Process.get(@key), request)

  defp respond(nil, _decoded), do: {:error, :not_configured}
  defp respond(script, decoded), do: script.(decoded)
end
