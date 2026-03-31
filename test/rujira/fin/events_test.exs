defmodule Rujira.Fin.EventsTest do
  use ExUnit.Case, async: true

  alias Rujira.Events.Event
  alias Rujira.Fin.Events

  defp event(type, attrs), do: Event.new(type, attrs)

  describe "parse/1" do
    test "parses trade event" do
      e =
        event("wasm-rujira-fin/trade", %{
          "_contract_address" => "thor1abc",
          "side" => "Base",
          "price" => "fixed:1000000",
          "rate" => "1.5",
          "offer" => "100",
          "bid" => "150",
          "ranges" => "0,1,2"
        })

      assert {:ok,
              %Events.Trade{
                contract: "thor1abc",
                side: :base,
                price: "fixed:1000000",
                offer: 100,
                bid: 150,
                ranges: "0,1,2"
              }} = Events.parse(e)
    end

    test "parses submit event" do
      e =
        event("wasm-rujira-fin/submit", %{
          "_contract_address" => "thor1abc",
          "side" => "Quote",
          "price" => "fixed:500",
          "owner" => "thor1owner"
        })

      assert {:ok,
              %Events.Submit{
                contract: "thor1abc",
                side: :quote,
                price: "fixed:500",
                owner: "thor1owner"
              }} = Events.parse(e)
    end

    test "parses retract event" do
      e =
        event("wasm-rujira-fin/retract", %{
          "_contract_address" => "thor1abc",
          "side" => "Base",
          "price" => "oracle:0",
          "owner" => "thor1owner"
        })

      assert {:ok,
              %Events.Retract{
                contract: "thor1abc",
                side: :base,
                price: "oracle:0",
                owner: "thor1owner"
              }} = Events.parse(e)
    end

    test "parses range.create event" do
      e =
        event("wasm-rujira-fin/range.create", %{
          "_contract_address" => "thor1abc",
          "idx" => "5",
          "owner" => "thor1owner"
        })

      assert {:ok, %Events.RangeCreate{contract: "thor1abc", idx: 5, owner: "thor1owner"}} =
               Events.parse(e)
    end

    test "parses range.deposit event" do
      e =
        event("wasm-rujira-fin/range.deposit", %{
          "_contract_address" => "thor1abc",
          "idx" => "3",
          "owner" => "thor1x"
        })

      assert {:ok, %Events.RangeDeposit{contract: "thor1abc", idx: 3, owner: "thor1x"}} =
               Events.parse(e)
    end

    test "parses range.withdraw event" do
      e =
        event("wasm-rujira-fin/range.withdraw", %{
          "_contract_address" => "thor1abc",
          "idx" => "7",
          "owner" => "thor1y"
        })

      assert {:ok, %Events.RangeWithdraw{contract: "thor1abc", idx: 7, owner: "thor1y"}} =
               Events.parse(e)
    end

    test "parses range.close event" do
      e =
        event("wasm-rujira-fin/range.close", %{
          "_contract_address" => "thor1abc",
          "idx" => "1",
          "owner" => "thor1z"
        })

      assert {:ok, %Events.RangeClose{contract: "thor1abc", idx: 1, owner: "thor1z"}} =
               Events.parse(e)
    end

    test "parses range.claim event" do
      e =
        event("wasm-rujira-fin/range.claim", %{
          "_contract_address" => "thor1abc",
          "idx" => "2",
          "owner" => "thor1w"
        })

      assert {:ok, %Events.RangeClaim{contract: "thor1abc", idx: 2, owner: "thor1w"}} =
               Events.parse(e)
    end

    test "parses range.fee event" do
      e = event("wasm-rujira-fin/range.fee", %{"_contract_address" => "thor1abc", "idx" => "4"})

      assert {:ok, %Events.RangeFee{contract: "thor1abc", idx: 4}} = Events.parse(e)
    end

    test "returns default event for unknown type" do
      e = event("wasm-other/something", %{})

      assert {:ok, %Event{type: "wasm-other/something"}} = Events.parse(e)
    end
  end
end
