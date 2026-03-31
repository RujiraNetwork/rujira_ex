defmodule Rujira.Thorchain.EventsTest do
  use ExUnit.Case, async: true

  alias Rujira.Thorchain.Events

  test "parses swap" do
    assert %Events.Swap{pool: "BTC.BTC", id: "abc"} =
             Events.parse(%{type: "swap", attributes: %{"pool" => "BTC.BTC", "id" => "abc"}})
  end

  test "parses transfer" do
    assert %Events.Transfer{sender: "a", recipient: "b", amount: "100rune"} =
             Events.parse(%{
               type: "transfer",
               attributes: %{"sender" => "a", "recipient" => "b", "amount" => "100rune"}
             })
  end

  test "parses add_liquidity" do
    assert %Events.AddLiquidity{pool: "BTC.BTC"} =
             Events.parse(%{type: "add_liquidity", attributes: %{"pool" => "BTC.BTC"}})
  end

  test "parses withdraw" do
    assert %Events.Withdraw{pool: "ETH.ETH"} =
             Events.parse(%{type: "withdraw", attributes: %{"pool" => "ETH.ETH"}})
  end

  test "parses pending_liquidity" do
    assert %Events.PendingLiquidity{pool: "BTC.BTC"} =
             Events.parse(%{type: "pending_liquidity", attributes: %{"pool" => "BTC.BTC"}})
  end

  test "parses oracle_price" do
    assert %Events.OraclePrice{symbol: "ETH.ETH", price: "3800"} =
             Events.parse(%{
               type: "oracle_price",
               attributes: %{"symbol" => "ETH.ETH", "price" => "3800"}
             })
  end

  test "parses bond" do
    assert %Events.Bond{type: :bond} = Events.parse(%{type: "bond", attributes: %{}})
  end

  test "parses rebond" do
    assert %Events.Bond{type: :rebond} = Events.parse(%{type: "rebond", attributes: %{}})
  end

  test "parses set_mimir" do
    assert %Events.SetMimir{key: "Halt", value: "1"} =
             Events.parse(%{type: "set_mimir", attributes: %{"key" => "Halt", "value" => "1"}})
  end

  test "returns nil for unknown" do
    assert nil == Events.parse(%{type: "unknown", attributes: %{}})
  end
end
