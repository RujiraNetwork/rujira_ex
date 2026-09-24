defmodule Rujira.Staking.EventsTest do
  use ExUnit.Case, async: true

  alias Rujira.Events.Event
  alias Rujira.Staking.Events
  alias Rujira.Staking.Events.AccountBond
  alias Rujira.Staking.Events.AccountClaim
  alias Rujira.Staking.Events.AccountWithdraw
  alias Rujira.Staking.Events.Event, as: StakingEvent
  alias Rujira.Staking.Events.LiquidBond
  alias Rujira.Staking.Events.LiquidUnbond
  alias Rujira.Staking.Events.Settle

  defp parse(type, attrs) do
    Events.parse(Event.new(type, Map.put(attrs, "_contract_address", "thor1abc")))
  end

  describe "account events" do
    test "account.bond" do
      assert {:ok,
              %StakingEvent{
                address: "thor1abc",
                data: %AccountBond{owner: "thor1owner", amount: 1000}
              }} =
               parse("wasm-rujira-staking/account.bond", %{
                 "owner" => "thor1owner",
                 "amount" => "1000"
               })
    end

    test "account.claim" do
      assert {:ok, %StakingEvent{data: %AccountClaim{owner: "thor1owner", amount: 500}}} =
               parse("wasm-rujira-staking/account.claim", %{
                 "owner" => "thor1owner",
                 "amount" => "500"
               })
    end

    test "account.withdraw" do
      assert {:ok,
              %StakingEvent{
                data: %AccountWithdraw{owner: "thor1owner", amount: 300, rewards: 20}
              }} =
               parse("wasm-rujira-staking/account.withdraw", %{
                 "owner" => "thor1owner",
                 "amount" => "300",
                 "rewards" => "20"
               })
    end

    test "returns error when a required attribute is missing" do
      assert {:error, :invalid_attrs} =
               parse("wasm-rujira-staking/account.bond", %{"owner" => "thor1owner"})
    end
  end

  describe "liquid events" do
    test "liquid.bond" do
      assert {:ok,
              %StakingEvent{data: %LiquidBond{owner: "thor1owner", amount: 1000, shares: 900}}} =
               parse("wasm-rujira-staking/liquid.bond", %{
                 "owner" => "thor1owner",
                 "amount" => "1000",
                 "shares" => "900"
               })
    end

    test "liquid.unbond" do
      assert {:ok,
              %StakingEvent{
                data: %LiquidUnbond{owner: "thor1owner", shares: 900, returned: 950}
              }} =
               parse("wasm-rujira-staking/liquid.unbond", %{
                 "owner" => "thor1owner",
                 "shares" => "900",
                 "returned" => "950"
               })
    end
  end

  describe "settle" do
    test "parses the returned amount" do
      assert {:ok, %StakingEvent{data: %Settle{returned: 42}}} =
               parse("wasm-rujira-staking/settle", %{"returned" => "42"})
    end
  end

  describe "fallbacks" do
    test "wraps unknown sub-type in the envelope" do
      assert {:ok, %StakingEvent{address: "thor1abc", data: %Event{}}} =
               parse("wasm-rujira-staking/unknown_action", %{})
    end

    test "wraps a non-wasm event with nil address" do
      e = Event.new("something_else", %{})

      assert {:ok, %StakingEvent{address: nil, data: %Event{type: "something_else"}}} =
               Events.parse(e)
    end
  end
end
