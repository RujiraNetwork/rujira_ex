defmodule Rujira.Ghost.Credit.EventsTest do
  use ExUnit.Case, async: true

  alias Rujira.Events.Event
  alias Rujira.Ghost.Credit.Events
  alias Rujira.Ghost.Credit.Events.AccountCreate
  alias Rujira.Ghost.Credit.Events.AccountLiquidate
  alias Rujira.Ghost.Credit.Events.AccountMsg
  alias Rujira.Ghost.Credit.Events.AccountMsgBorrow
  alias Rujira.Ghost.Credit.Events.AccountMsgExecute
  alias Rujira.Ghost.Credit.Events.AccountMsgRepay
  alias Rujira.Ghost.Credit.Events.AccountMsgSend
  alias Rujira.Ghost.Credit.Events.AccountMsgSetPreferenceMsgs
  alias Rujira.Ghost.Credit.Events.AccountMsgSetPreferenceOrder
  alias Rujira.Ghost.Credit.Events.AccountMsgTransfer
  alias Rujira.Ghost.Credit.Events.Event, as: CreditEvent
  alias Rujira.Ghost.Credit.Events.LiquidateMsgExecute
  alias Rujira.Ghost.Credit.Events.LiquidateMsgPreferenceError
  alias Rujira.Ghost.Credit.Events.LiquidateMsgRepay

  defp parse(action, attrs) do
    Events.parse(
      Event.new(
        "wasm-rujira-ghost-credit/" <> action,
        Map.put(attrs, "_contract_address", "thor1credit")
      )
    )
  end

  describe "account lifecycle" do
    test "account.create" do
      assert {:ok,
              %CreditEvent{
                address: "thor1credit",
                data: %AccountCreate{owner: "thor1owner", address: "thor1account"}
              }} =
               parse("account.create", %{"owner" => "thor1owner", "address" => "thor1account"})
    end

    test "account.create without an address is an error" do
      assert {:error, :invalid_attrs} = parse("account.create", %{"owner" => "thor1owner"})
    end

    test "account.msg" do
      assert {:ok, %CreditEvent{data: %AccountMsg{owner: "thor1owner", address: "thor1account"}}} =
               parse("account.msg", %{"owner" => "thor1owner", "address" => "thor1account"})
    end

    test "account.msg without an owner is an error" do
      assert {:error, :invalid_attrs} = parse("account.msg", %{"address" => "thor1account"})
    end

    test "account.liquidate" do
      assert {:ok,
              %CreditEvent{
                data: %AccountLiquidate{
                  owner: "thor1owner",
                  address: "thor1account",
                  caller: "thor1liquidator"
                }
              }} =
               parse("account.liquidate", %{
                 "owner" => "thor1owner",
                 "address" => "thor1account",
                 "caller" => "thor1liquidator"
               })
    end

    test "account.liquidate without a caller is an error" do
      assert {:error, :invalid_attrs} =
               parse("account.liquidate", %{"owner" => "thor1owner", "address" => "thor1account"})
    end
  end

  describe "account messages" do
    test "account.msg/borrow parses the amount as a coin" do
      assert {:ok, %CreditEvent{data: %AccountMsgBorrow{amount: amount}}} =
               parse("account.msg/borrow", %{"amount" => "1000rune"})

      assert amount.asset.id == "THOR.RUNE"
      assert amount.amount == 1000
    end

    test "account.msg/borrow with an unparseable amount is an error" do
      assert {:error, :invalid_coin_format} = parse("account.msg/borrow", %{"amount" => "rune"})
    end

    test "account.msg/repay parses the amount as a coin" do
      assert {:ok, %CreditEvent{data: %AccountMsgRepay{amount: amount}}} =
               parse("account.msg/repay", %{"amount" => "500btc-btc"})

      assert amount.asset.id == "BTC-BTC"
      assert amount.amount == 500
    end

    test "account.msg/repay with no amount is an error" do
      assert {:error, :invalid_attrs} = parse("account.msg/repay", %{})
    end

    test "account.msg/execute decodes msg and drops the funds attribute" do
      assert {:ok, %CreditEvent{data: %AccountMsgExecute{} = data}} =
               parse("account.msg/execute", %{
                 "contract_addr" => "thor1fin",
                 "msg" => Base.encode64(~s({"swap":{}})),
                 "funds" => "100btc-btc200eth-eth"
               })

      assert data.contract == "thor1fin"
      assert data.msg == ~s({"swap":{}})
      refute Map.has_key?(data, :funds)
    end

    test "account.msg/execute with a msg that is not base64 is an error" do
      assert {:error, :invalid_msg} =
               parse("account.msg/execute", %{"contract_addr" => "thor1fin", "msg" => "!!"})
    end

    test "account.msg/send keeps the recipient and drops the funds attribute" do
      assert {:ok, %CreditEvent{data: %AccountMsgSend{to_address: "thor1dest"} = data}} =
               parse("account.msg/send", %{
                 "to_address" => "thor1dest",
                 "funds" => "100btc-btc200eth-eth"
               })

      refute Map.has_key?(data, :funds)
    end

    test "account.msg/send without a to_address is an error" do
      assert {:error, :invalid_attrs} = parse("account.msg/send", %{"funds" => "100rune"})
    end

    test "account.msg/transfer reads the contract's misspelled recipient key" do
      assert {:ok, %CreditEvent{data: %AccountMsgTransfer{recipient: "thor1new"}}} =
               parse("account.msg/transfer", %{"to_adrecipientdress" => "thor1new"})
    end

    test "account.msg/transfer under the correctly spelled key is an error" do
      assert {:error, :invalid_attrs} =
               parse("account.msg/transfer", %{"to_address" => "thor1new"})
    end

    test "account.msg/set_preference_order" do
      assert {:ok, %CreditEvent{data: %AccountMsgSetPreferenceOrder{} = data}} =
               parse("account.msg/set_preference_order", %{
                 "denom" => "btc-btc",
                 "after" => "eth-eth"
               })

      assert data.asset.id == "BTC-BTC"
      assert data.after.id == "ETH-ETH"
    end

    test "account.msg/set_preference_order with an empty after is a removed constraint" do
      assert {:ok, %CreditEvent{data: %AccountMsgSetPreferenceOrder{after: nil} = data}} =
               parse("account.msg/set_preference_order", %{"denom" => "btc-btc", "after" => ""})

      assert data.asset.id == "BTC-BTC"
    end

    test "account.msg/set_preference_order with an unrecognised denom is an error" do
      assert {:error, :invalid_denom} =
               parse("account.msg/set_preference_order", %{
                 "denom" => "not a denom",
                 "after" => ""
               })
    end

    # The contract emits no attributes for this one, so there is no malformed
    # form of it - only the envelope it arrives in.
    test "account.msg/set_preference_msgs carries no attributes" do
      assert {:ok, %CreditEvent{data: %AccountMsgSetPreferenceMsgs{}}} =
               parse("account.msg/set_preference_msgs", %{})
    end
  end

  describe "liquidation messages" do
    test "liquidate.msg/preference.error" do
      assert {:ok, %CreditEvent{data: %LiquidateMsgPreferenceError{error: "Generic error: nope"}}} =
               parse("liquidate.msg/preference.error", %{"error" => "Generic error: nope"})
    end

    test "liquidate.msg/preference.error without an error is an error" do
      assert {:error, :invalid_attrs} = parse("liquidate.msg/preference.error", %{})
    end

    test "liquidate.msg/repay" do
      assert {:ok,
              %CreditEvent{
                data:
                  %LiquidateMsgRepay{
                    repay_amount: 970,
                    fee_liquidation: 10,
                    fee_liquidator: 20
                  } = data
              }} =
               parse("liquidate.msg/repay", %{
                 "amount" => "1000rune",
                 "repay_amount" => "970",
                 "fee_liquidation" => "10",
                 "fee_liquidator" => "20"
               })

      assert data.amount.asset.id == "THOR.RUNE"
      assert data.amount.amount == 1000
    end

    test "liquidate.msg/repay with an unparseable fee is an error" do
      assert {:error, :invalid_amount} =
               parse("liquidate.msg/repay", %{
                 "amount" => "1000rune",
                 "repay_amount" => "970",
                 "fee_liquidation" => "ten",
                 "fee_liquidator" => "20"
               })
    end

    test "liquidate.msg/execute decodes msg and drops the funds attribute" do
      assert {:ok, %CreditEvent{data: %LiquidateMsgExecute{} = data}} =
               parse("liquidate.msg/execute", %{
                 "contract_addr" => "thor1fin",
                 "msg" => Base.encode64(~s({"swap":{}})),
                 "funds" => "100btc-btc200eth-eth"
               })

      assert data.contract == "thor1fin"
      assert data.msg == ~s({"swap":{}})
      refute Map.has_key?(data, :funds)
    end

    test "liquidate.msg/execute without a contract_addr is an error" do
      assert {:error, :invalid_attrs} =
               parse("liquidate.msg/execute", %{"msg" => Base.encode64("{}")})
    end
  end

  describe "unknown events" do
    test "an unrecognised action keeps the raw event in the envelope" do
      assert {:ok, %CreditEvent{address: "thor1credit", data: %Event{type: type}}} =
               parse("account.msg/something_new", %{"foo" => "bar"})

      assert type == "wasm-rujira-ghost-credit/account.msg/something_new"
    end

    test "an event with no contract address keeps the raw event and no address" do
      assert {:ok, %CreditEvent{address: nil, data: %Event{}}} =
               Events.parse(Event.new("wasm-rujira-ghost-credit/account.create", %{}))
    end
  end
end
