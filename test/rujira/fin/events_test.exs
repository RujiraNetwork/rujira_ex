defmodule Rujira.Fin.EventsTest do
  use ExUnit.Case, async: true

  alias Rujira.Fin.Events

  describe "parse/1" do
    test "parses trade event" do
      event = %{
        type: "wasm-rujira-fin/trade",
        attributes: %{
          "_contract_address" => "thor1abc",
          "side" => "base",
          "price" => "fixed:1000000",
          "rate" => "1.5",
          "offer" => "100",
          "bid" => "150",
          "ranges" => "0,1,2"
        }
      }

      assert %Events.Trade{
               contract: "thor1abc",
               side: "base",
               price: "fixed:1000000",
               rate: "1.5",
               offer: "100",
               bid: "150",
               ranges: "0,1,2"
             } = Events.parse(event)
    end

    test "parses submit event" do
      event = %{
        type: "wasm-rujira-fin/submit",
        attributes: %{
          "_contract_address" => "thor1abc",
          "side" => "quote",
          "price" => "fixed:500",
          "owner" => "thor1owner"
        }
      }

      assert %Events.Submit{
               contract: "thor1abc",
               side: "quote",
               price: "fixed:500",
               owner: "thor1owner"
             } = Events.parse(event)
    end

    test "parses retract event" do
      event = %{
        type: "wasm-rujira-fin/retract",
        attributes: %{
          "_contract_address" => "thor1abc",
          "side" => "base",
          "price" => "oracle:0",
          "owner" => "thor1owner"
        }
      }

      assert %Events.Retract{
               contract: "thor1abc",
               side: "base",
               price: "oracle:0",
               owner: "thor1owner"
             } = Events.parse(event)
    end

    test "parses range.create event" do
      event = %{
        type: "wasm-rujira-fin/range.create",
        attributes: %{
          "_contract_address" => "thor1abc",
          "idx" => "5",
          "owner" => "thor1owner"
        }
      }

      assert %Events.RangeCreate{contract: "thor1abc", idx: "5", owner: "thor1owner"} =
               Events.parse(event)
    end

    test "parses range.deposit event" do
      event = %{
        type: "wasm-rujira-fin/range.deposit",
        attributes: %{"_contract_address" => "thor1abc", "idx" => "3", "owner" => "thor1x"}
      }

      assert %Events.RangeDeposit{contract: "thor1abc", idx: "3", owner: "thor1x"} =
               Events.parse(event)
    end

    test "parses range.withdraw event" do
      event = %{
        type: "wasm-rujira-fin/range.withdraw",
        attributes: %{"_contract_address" => "thor1abc", "idx" => "7", "owner" => "thor1y"}
      }

      assert %Events.RangeWithdraw{contract: "thor1abc", idx: "7", owner: "thor1y"} =
               Events.parse(event)
    end

    test "parses range.close event" do
      event = %{
        type: "wasm-rujira-fin/range.close",
        attributes: %{"_contract_address" => "thor1abc", "idx" => "1", "owner" => "thor1z"}
      }

      assert %Events.RangeClose{contract: "thor1abc", idx: "1", owner: "thor1z"} =
               Events.parse(event)
    end

    test "parses range.claim event" do
      event = %{
        type: "wasm-rujira-fin/range.claim",
        attributes: %{"_contract_address" => "thor1abc", "idx" => "2", "owner" => "thor1w"}
      }

      assert %Events.RangeClaim{contract: "thor1abc", idx: "2", owner: "thor1w"} =
               Events.parse(event)
    end

    test "parses range.fee event" do
      event = %{
        type: "wasm-rujira-fin/range.fee",
        attributes: %{"_contract_address" => "thor1abc", "idx" => "4"}
      }

      assert %Events.RangeFee{contract: "thor1abc", idx: "4"} = Events.parse(event)
    end

    test "returns nil for unknown event type" do
      assert Events.parse(%{type: "wasm-other/something", attributes: %{}}) == nil
    end

    test "returns nil for non-map input" do
      assert Events.parse("not a map") == nil
    end
  end
end
