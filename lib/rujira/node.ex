defmodule Rujira.Node do
  @moduledoc """
  Behaviour and configurable delegator for chain node queries.

  Consumers configure the implementation via application env:

      config :rujira_ex, node: MyApp.NodeImpl

  The implementation must export `query/3`.
  """

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
