defmodule Rujira.Revenue.EventsTest do
  use ExUnit.Case, async: true

  alias Rujira.Events.Event
  alias Rujira.Revenue.Events
  alias Rujira.Revenue.Events.Event, as: RevenueEvent
  alias Rujira.Revenue.Events.Run

  defp parse(type, attrs) do
    Events.parse(Event.new(type, Map.put(attrs, "_contract_address", "thor1abc")))
  end

  defp run_attrs(extra \\ %{}) do
    Map.merge(
      %{
        "denom" => "rune"
      },
      extra
    )
  end

  describe "run" do
    test "parses native denom into the envelope" do
      assert {:ok, %RevenueEvent{address: "thor1abc", data: data}} =
               parse("wasm-rujira-revenue/run", run_attrs())

      assert %Run{asset: %{id: "THOR.RUNE"}} = data
    end

    test "parses secured denom into the envelope" do
      assert {:ok, %RevenueEvent{address: "thor1abc", data: data}} =
               parse("wasm-rujira-revenue/run", run_attrs(%{"denom" => "btc-btc"}))

      assert %Run{asset: %{id: "BTC-BTC"}} = data
    end

    test "returns error when denom is missing" do
      assert {:error, :invalid_attrs} =
               parse("wasm-rujira-revenue/run", Map.delete(run_attrs(), "denom"))
    end

    test "returns error when denom is empty string" do
      assert {:error, :invalid_denom} =
               parse("wasm-rujira-revenue/run", run_attrs(%{"denom" => ""}))
    end

    test "returns error when denom is unresolvable" do
      assert {:error, :invalid_denom} =
               parse("wasm-rujira-revenue/run", run_attrs(%{"denom" => "invalid"}))
    end
  end

  describe "fallbacks" do
    test "wraps unknown sub-type in the envelope" do
      assert {:ok, %RevenueEvent{address: "thor1abc", data: %Event{}}} =
               parse("wasm-rujira-revenue/unknown_action", %{})
    end

    test "wraps a non-wasm event with nil address" do
      e = Event.new("something_else", %{})

      assert {:ok, %RevenueEvent{address: nil, data: %Event{type: "something_else"}}} =
               Events.parse(e)
    end
  end
end
