defmodule Rujira.Node.Subscription.Message do
  @moduledoc """
  The CometBFT websocket JSON-RPC messages `Rujira.Node.Subscription` sends
  and reads. Pure: no socket, no process.

  One request is sent per connection:

      {"jsonrpc":"2.0","method":"subscribe","id":1,
       "params":{"query":"tm.event='NewBlockHeader'"}}

  The node acknowledges it with an empty result under the same id, then sends
  one message per committed block under that id. Only the header's `height`
  is read; the rest of the header is ignored, because the consumer fetches
  the block itself over gRPC.

      {"jsonrpc":"2.0","id":1,"result":{}}
      {"jsonrpc":"2.0","id":1,"result":{"query":"tm.event='NewBlockHeader'",
       "data":{"type":"tendermint/event/NewBlockHeader",
               "value":{"header":{"height":"28446896", ...}}},
       "events":{"tm.event":["NewBlockHeader"]}}}

  A refused subscription, or one the node cancels later (a client too slow to
  read, a node shutting down), is a JSON-RPC error:

      {"jsonrpc":"2.0","id":1,"error":{"code":-32603,"message":"Internal error",
       "data":"failed to parse query: ..."}}
  """

  alias Rujira.Math

  @query "tm.event='NewBlockHeader'"
  @event_type "tendermint/event/NewBlockHeader"

  @typedoc "A JSON-RPC request id."
  @type id :: integer() | String.t() | nil

  @typedoc "What a text frame from the node says."
  @type t ::
          {:subscribed, id()}
          | {:new_block, id(), pos_integer()}
          | {:rpc_error, id(), map()}

  # --- Construction ---

  @doc "The JSON-RPC request subscribing to every new block header, under `id`."
  @spec subscribe(id()) :: String.t()
  def subscribe(id) do
    JSON.encode!(%{
      "jsonrpc" => "2.0",
      "method" => "subscribe",
      "id" => id,
      "params" => %{"query" => @query}
    })
  end

  @doc """
  Reads one text frame from the node.

    * `{:ok, {:subscribed, id}}` - the acknowledgement of a subscribe request.
    * `{:ok, {:new_block, id, height}}` - a new block header.
    * `{:ok, {:rpc_error, id, error}}` - a JSON-RPC error; `id` is `nil` when
      the node could not read the request it answers.
    * `{:error, :invalid_message}` - anything else: not JSON, not JSON-RPC, a
      result of another kind, or a header without a positive integer height.
  """
  @spec parse(String.t()) :: {:ok, t()} | {:error, :invalid_message}
  def parse(text) when is_binary(text) do
    case JSON.decode(text) do
      {:ok, %{"jsonrpc" => "2.0"} = message} -> from_rpc(message)
      _ -> {:error, :invalid_message}
    end
  end

  # --- Private ---

  defp from_rpc(%{"error" => %{} = error} = message),
    do: {:ok, {:rpc_error, Map.get(message, "id"), error}}

  defp from_rpc(%{"result" => result} = message) when result == %{},
    do: {:ok, {:subscribed, Map.get(message, "id")}}

  defp from_rpc(
         %{
           "result" => %{
             "data" => %{"type" => @event_type, "value" => %{"header" => %{"height" => height}}}
           }
         } = message
       ) do
    case Math.to_integer(height) do
      {:ok, height} when is_integer(height) and height > 0 ->
        {:ok, {:new_block, Map.get(message, "id"), height}}

      _ ->
        {:error, :invalid_message}
    end
  end

  defp from_rpc(_message), do: {:error, :invalid_message}
end
