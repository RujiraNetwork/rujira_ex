defmodule Rujira.Node do
  @moduledoc """
  Behaviour and configurable delegator for chain node queries.

  Consumers configure the implementation via application env:

      config :rujira_ex, node: MyApp.NodeImpl

  The implementation must export `query/3`.
  """

  @type query_fun ::
          (GRPC.Channel.t(), term() -> {:ok, term()} | {:error, GRPC.RPCError.t() | term()})

  @type query_fun3 ::
          (GRPC.Channel.t(), term(), keyword() ->
             {:ok, term()} | {:error, GRPC.RPCError.t() | term()})

  @callback query(query_fun() | query_fun3(), term(), keyword()) ::
              {:ok, term()} | {:error, term()}

  @spec query(query_fun() | query_fun3(), term(), keyword()) :: {:ok, term()} | {:error, term()}
  def query(fun, request, opts \\ []) do
    impl().query(fun, request, opts)
  end

  defp impl do
    Application.get_env(:rujira_ex, :node) ||
      raise "No :node implementation configured for :rujira_ex. " <>
              "Set `config :rujira_ex, node: YourNodeModule`"
  end
end
