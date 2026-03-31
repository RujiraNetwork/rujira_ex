defmodule Rujira.EventsTest do
  use ExUnit.Case, async: true

  alias Rujira.Events
  alias Rujira.Fin.Events, as: FinEvents
  alias Rujira.Thorchain.Events, as: TcEvents

  describe "parse/1 — FIN routing" do
    test "routes wasm-rujira-fin/* to Fin.Events" do
      event = %{
        type: "wasm-rujira-fin/trade",
        attributes: %{"_contract_address" => "thor1abc", "side" => "base", "price" => "fixed:100"}
      }

      assert %FinEvents.Trade{contract: "thor1abc", side: "base"} = Events.parse(event)
    end

    test "routes range events to Fin.Events" do
      event = %{
        type: "wasm-rujira-fin/range.create",
        attributes: %{"_contract_address" => "thor1abc", "idx" => "1", "owner" => "thor1x"}
      }

      assert %FinEvents.RangeCreate{contract: "thor1abc"} = Events.parse(event)
    end
  end

  describe "parse/1 — Thorchain native routing" do
    test "routes swap" do
      assert %TcEvents.Swap{pool: "BTC.BTC"} =
               Events.parse(%{type: "swap", attributes: %{"pool" => "BTC.BTC"}})
    end

    test "routes transfer" do
      assert %TcEvents.Transfer{sender: "a", recipient: "b"} =
               Events.parse(%{
                 type: "transfer",
                 attributes: %{"sender" => "a", "recipient" => "b", "amount" => "1"}
               })
    end

    test "routes oracle_price" do
      assert %TcEvents.OraclePrice{symbol: "ETH.ETH"} =
               Events.parse(%{type: "oracle_price", attributes: %{"symbol" => "ETH.ETH"}})
    end

    test "routes set_mimir" do
      assert %TcEvents.SetMimir{key: "Halt"} =
               Events.parse(%{type: "set_mimir", attributes: %{"key" => "Halt"}})
    end

    test "routes bond" do
      assert %TcEvents.Bond{type: :bond} =
               Events.parse(%{type: "bond", attributes: %{}})
    end
  end

  describe "parse/1 — unmatched" do
    test "returns nil for not-yet-implemented protocols" do
      assert nil == Events.parse(%{type: "wasm-rujira-bow/swap", attributes: %{}})
    end

    test "returns nil for unknown events" do
      assert nil == Events.parse(%{type: "something_random", attributes: %{}})
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

      assert %TcEvents.OraclePrice{symbol: "ETH.ETH", price: "3800"} = Events.parse(block_event)
    end
  end
end
