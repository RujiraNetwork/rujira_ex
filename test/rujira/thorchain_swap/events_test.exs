defmodule Rujira.ThorchainSwap.EventsTest do
  use ExUnit.Case, async: true

  alias Rujira.Coin
  alias Rujira.Events.Event
  alias Rujira.ThorchainSwap.Events
  alias Rujira.ThorchainSwap.Events.Event, as: ThorchainSwapEvent
  alias Rujira.ThorchainSwap.Events.Swap

  defp parse(type, attrs) do
    Events.parse(Event.new(type, Map.put(attrs, "_contract_address", "thor1abc")))
  end

  defp swap_attrs(extra \\ %{}) do
    Map.merge(
      %{
        "amount" => "58btc-btc",
        "quote_return" => "991226rune",
        "min_return" => "900000rune",
        "reserve_fee" => "199rune",
        "amm_fee" => "14868rune",
        "returned" => "900000rune",
        "memo" => "dummy"
      },
      extra
    )
  end

  describe "swap" do
    test "parses coin attributes and memo into the envelope" do
      assert {:ok, %ThorchainSwapEvent{address: "thor1abc", data: data}} =
               parse("wasm-rujira-thorchain-swap/swap", swap_attrs())

      assert %Swap{memo: "dummy"} = data
      assert %Coin{amount: 58} = data.amount
      assert data.amount.asset.ticker == "BTC"
      assert %Coin{amount: 991_226} = data.quote_return
      assert data.quote_return.asset.ticker == "RUNE"
      assert %Coin{amount: 900_000} = data.min_return
      assert %Coin{amount: 199} = data.reserve_fee
      assert %Coin{amount: 14_868} = data.amm_fee
      assert %Coin{amount: 900_000} = data.returned
    end

    test "returns error when a coin attribute is missing" do
      assert {:error, :invalid_attrs} =
               parse("wasm-rujira-thorchain-swap/swap", Map.delete(swap_attrs(), "amount"))
    end
  end

  describe "fallbacks" do
    test "wraps unknown sub-type in the envelope" do
      assert {:ok, %ThorchainSwapEvent{address: "thor1abc", data: %Event{}}} =
               parse("wasm-rujira-thorchain-swap/unknown_action", %{})
    end

    test "wraps a non-wasm event with nil address" do
      e = Event.new("something_else", %{})

      assert {:ok, %ThorchainSwapEvent{address: nil, data: %Event{type: "something_else"}}} =
               Events.parse(e)
    end
  end
end
