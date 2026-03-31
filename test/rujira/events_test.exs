defmodule Rujira.EventsTest do
  use ExUnit.Case, async: true

  alias Rujira.Events
  alias Rujira.Fin.Events, as: FinEvents
  alias Rujira.Thorchain.Events, as: TcEvents

  describe "parse/1 — FIN routing" do
    test "routes wasm-rujira-fin/* to Fin.Events" do
      event = %{
        type: "wasm-rujira-fin/trade",
        attributes: %{"_contract_address" => "thor1abc", "side" => "Base", "price" => "100"}
      }

      assert {:ok, %FinEvents.Trade{contract: "thor1abc", side: :base}} = Events.parse(event)
    end

    test "routes range events to Fin.Events" do
      event = %{
        type: "wasm-rujira-fin/range.create",
        attributes: %{"_contract_address" => "thor1abc", "idx" => "1", "owner" => "thor1x"}
      }

      assert {:ok, %FinEvents.RangeCreate{contract: "thor1abc", idx: 1}} = Events.parse(event)
    end
  end

  describe "parse/1 — Thorchain native routing" do
    test "routes swap" do
      assert {:ok, %TcEvents.Swap{pool: "BTC.BTC"}} =
               Events.parse(%{type: "swap", attributes: %{"pool" => "BTC.BTC"}})
    end

    test "routes transfer" do
      assert {:ok, %TcEvents.Transfer{sender: "a", recipient: "b", amount: 1}} =
               Events.parse(%{
                 type: "transfer",
                 attributes: %{"sender" => "a", "recipient" => "b", "amount" => "1"}
               })
    end

    test "routes oracle_price" do
      assert {:ok, %TcEvents.OraclePrice{symbol: "ETH.ETH"}} =
               Events.parse(%{type: "oracle_price", attributes: %{"symbol" => "ETH.ETH"}})
    end

    test "routes set_mimir" do
      assert {:ok, %TcEvents.SetMimir{key: "Halt"}} =
               Events.parse(%{type: "set_mimir", attributes: %{"key" => "Halt"}})
    end

    test "routes bond" do
      assert {:ok, %TcEvents.Bond{type: :bond}} =
               Events.parse(%{type: "bond", attributes: %{}})
    end
  end

  describe "parse/1 — unmatched" do
    test "returns default event for not-yet-implemented protocols" do
      assert {:ok, %Rujira.Events.Event{type: "wasm-rujira-bow/swap", attributes: %{}}} =
               Events.parse(%{type: "wasm-rujira-bow/swap", attributes: %{}})
    end

    test "returns default event for unknown events" do
      assert {:ok, %Rujira.Events.Event{type: "something_random", attributes: %{}}} =
               Events.parse(%{type: "something_random", attributes: %{}})
    end

    test "returns error for invalid input" do
      assert {:error, :invalid_event} = Events.parse("not an event")
    end
  end

  describe "cast/1" do
    test "casts BlockEvent proto to map" do
      block_event = %Thorchain.Types.BlockEvent{
        event_kv_pair: [
          %{key: "type", value: "swap"},
          %{key: "pool", value: "BTC.BTC"},
          %{key: "id", value: "123"}
        ]
      }

      assert %{type: "swap", attributes: %{"pool" => "BTC.BTC", "id" => "123"}} =
               Events.cast(block_event)
    end
  end

  describe "parse/1 — raw BlockEvent proto" do
    test "casts and parses in one step" do
      block_event = %Thorchain.Types.BlockEvent{
        event_kv_pair: [
          %{key: "type", value: "oracle_price"},
          %{key: "symbol", value: "ETH.ETH"},
          %{key: "price", value: "3800"}
        ]
      }

      assert {:ok, %TcEvents.OraclePrice{symbol: "ETH.ETH", price: price}} =
               Events.parse(block_event)

      assert Decimal.equal?(price, Decimal.new("3800"))
    end
  end
end
