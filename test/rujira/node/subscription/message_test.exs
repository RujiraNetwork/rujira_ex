defmodule Rujira.Node.Subscription.MessageTest do
  use ExUnit.Case, async: true

  alias Rujira.Node.Subscription.Message

  @fixtures "test/fixtures/websocket"

  describe "subscribe/1" do
    test "is the JSON-RPC subscribe request for new block headers" do
      assert JSON.decode!(Message.subscribe(7)) == %{
               "jsonrpc" => "2.0",
               "method" => "subscribe",
               "id" => 7,
               "params" => %{"query" => "tm.event='NewBlockHeader'"}
             }
    end
  end

  describe "parse/1 on frames captured from a mainnet node" do
    test "the subscribe acknowledgement" do
      assert Message.parse(File.read!("#{@fixtures}/subscribe_result.json")) ==
               {:ok, {:subscribed, 7}}
    end

    test "a NewBlockHeader event" do
      assert Message.parse(File.read!("#{@fixtures}/new_block_header.json")) ==
               {:ok, {:new_block, 7, 28_446_896}}
    end

    test "a refused subscription" do
      assert {:ok,
              {:rpc_error, "x", %{"code" => -32_603, "data" => "failed to parse query" <> _}}} =
               Message.parse(File.read!("#{@fixtures}/subscribe_error.json"))
    end
  end

  describe "parse/1 on anything else" do
    test "an error without an id" do
      assert Message.parse(~s({"jsonrpc":"2.0","error":{"code":-32700}})) ==
               {:ok, {:rpc_error, nil, %{"code" => -32_700}}}
    end

    test "is :invalid_message" do
      event = "#{@fixtures}/new_block_header.json" |> File.read!() |> JSON.decode!()
      with_height = &put_in(event, ["result", "data", "value", "header", "height"], &1)

      for text <- [
            "",
            "not json",
            "[]",
            ~s({"id":1,"result":{}}),
            ~s({"jsonrpc":"1.0","id":1,"result":{}}),
            ~s({"jsonrpc":"2.0","id":1}),
            ~s({"jsonrpc":"2.0","id":1,"result":{"data":{}}}),
            ~s({"jsonrpc":"2.0","id":1,"result":{"data":{"type":"tendermint/event/Tx","value":{}}}}),
            JSON.encode!(with_height.("")),
            JSON.encode!(with_height.("0")),
            JSON.encode!(with_height.("-3")),
            JSON.encode!(with_height.("12a")),
            JSON.encode!(with_height.(nil))
          ] do
        assert Message.parse(text) == {:error, :invalid_message}, text
      end
    end

    test "a height sent as a JSON number is read too" do
      event = "#{@fixtures}/new_block_header.json" |> File.read!() |> JSON.decode!()
      text = event |> put_in(["result", "data", "value", "header", "height"], 5) |> JSON.encode!()
      assert Message.parse(text) == {:ok, {:new_block, 7, 5}}
    end
  end
end
