defmodule Rujira.Test.MockNode do
  @moduledoc """
  Mock node implementation for tests.

  By default every query is unconfigured. A test can script smart-contract
  queries with `expect/1`, which receives the decoded query map and returns
  whatever `Rujira.Node.query/3` should hand back:

      MockNode.expect(fn
        %{"ranges" => %{"dynamic" => _}} -> {:error, %GRPC.RPCError{...}}
        %{"ranges" => _} -> MockNode.ok(%{"ranges" => []})
      end)

  The script lives in the process dictionary, so it is per-test and safe under
  `async: true`.
  """
  @behaviour Rujira.Node

  alias Cosmwasm.Wasm.V1.QuerySmartContractStateRequest

  @key :mock_node_script

  @doc "Scripts smart-contract queries for the current process."
  @spec expect((map() -> {:ok, term()} | {:error, term()})) :: :ok
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
    respond(Process.get(@key), query_data)
  end

  def query(_fun, _request, _opts), do: {:error, :not_configured}

  defp respond(nil, _query_data), do: {:error, :not_configured}
  defp respond(script, query_data), do: script.(JSON.decode!(query_data))
end
