defmodule Rujira.Thorchain.EventsTest do
  use ExUnit.Case, async: true

  alias Rujira.Events.Event
  alias Rujira.Thorchain.Events

  defp event(type, attrs), do: Event.new(type, attrs)

  test "parses swap" do
    assert {:ok, %Events.Swap{pool: "BTC.BTC", id: "abc"}} =
             Events.parse(event("swap", %{"pool" => "BTC.BTC", "id" => "abc"}))
  end

  test "parses transfer" do
    assert {:ok, %Events.Transfer{sender: "a", recipient: "b", amount: 100}} =
             Events.parse(
               event("transfer", %{"sender" => "a", "recipient" => "b", "amount" => "100"})
             )
  end

  test "parses add_liquidity" do
    assert {:ok, %Events.AddLiquidity{pool: "BTC.BTC"}} =
             Events.parse(event("add_liquidity", %{"pool" => "BTC.BTC"}))
  end

  test "parses withdraw" do
    assert {:ok, %Events.Withdraw{pool: "ETH.ETH"}} =
             Events.parse(event("withdraw", %{"pool" => "ETH.ETH"}))
  end

  test "parses pending_liquidity" do
    assert {:ok, %Events.PendingLiquidity{pool: "BTC.BTC"}} =
             Events.parse(event("pending_liquidity", %{"pool" => "BTC.BTC"}))
  end

  test "parses oracle_price" do
    assert {:ok, %Events.OraclePrice{symbol: "ETH.ETH", price: price}} =
             Events.parse(event("oracle_price", %{"symbol" => "ETH.ETH", "price" => "3800"}))

    assert Decimal.equal?(price, Decimal.new("3800"))
  end

  test "parses bond" do
    assert {:ok, %Events.Bond{type: :bond}} =
             Events.parse(event("bond", %{}))
  end

  test "parses rebond" do
    assert {:ok, %Events.Bond{type: :rebond}} =
             Events.parse(event("rebond", %{}))
  end

  test "parses set_mimir" do
    assert {:ok, %Events.SetMimir{key: "Halt", value: "1"}} =
             Events.parse(event("set_mimir", %{"key" => "Halt", "value" => "1"}))
  end

  test "returns default event for unknown" do
    assert {:ok, %Event{type: "unknown"}} = Events.parse(event("unknown", %{}))
  end
end
