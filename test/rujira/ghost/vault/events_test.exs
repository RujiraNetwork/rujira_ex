defmodule Rujira.Ghost.Vault.EventsTest do
  use ExUnit.Case, async: true

  alias Rujira.Events.Event
  alias Rujira.Ghost.Vault.Events
  alias Rujira.Ghost.Vault.Events.Borrow
  alias Rujira.Ghost.Vault.Events.Deposit
  alias Rujira.Ghost.Vault.Events.Event, as: VaultEvent
  alias Rujira.Ghost.Vault.Events.Repay
  alias Rujira.Ghost.Vault.Events.Withdraw

  defp parse(type, attrs) do
    Events.parse(Event.new(type, Map.put(attrs, "_contract_address", "thor1abc")))
  end

  describe "deposit / withdraw" do
    test "deposit" do
      assert {:ok,
              %VaultEvent{
                address: "thor1abc",
                data: %Deposit{owner: "thor1owner", amount: 1000, shares: 1000}
              }} =
               parse("wasm-rujira-ghost-vault/deposit", %{
                 "owner" => "thor1owner",
                 "amount" => "1000",
                 "shares" => "1000"
               })
    end

    test "withdraw" do
      assert {:ok, %VaultEvent{data: %Withdraw{owner: "thor1owner", amount: 200, shares: 200}}} =
               parse("wasm-rujira-ghost-vault/withdraw", %{
                 "owner" => "thor1owner",
                 "amount" => "200",
                 "shares" => "200"
               })
    end
  end

  describe "borrow / repay" do
    test "borrow with no delegate parses shares as a decimal" do
      assert {:ok, %VaultEvent{data: data}} =
               parse("wasm-rujira-ghost-vault/borrow", %{
                 "borrower" => "thor1b",
                 "delegate" => "",
                 "amount" => "500",
                 "shares" => "500.5"
               })

      assert %Borrow{borrower: "thor1b", delegate: nil, amount: 500} = data
      assert Decimal.equal?(data.shares, Decimal.new("500.5"))
    end

    test "repay carries the delegate when present" do
      assert {:ok, %VaultEvent{data: %Repay{borrower: "thor1b", delegate: "thor1d", amount: 100}}} =
               parse("wasm-rujira-ghost-vault/repay", %{
                 "borrower" => "thor1b",
                 "delegate" => "thor1d",
                 "amount" => "100",
                 "shares" => "100"
               })
    end
  end

  describe "fallbacks" do
    test "wraps unknown sub-type in the envelope" do
      assert {:ok, %VaultEvent{address: "thor1abc", data: %Event{}}} =
               parse("wasm-rujira-ghost-vault/unknown_action", %{})
    end

    test "wraps a non-wasm event with nil address" do
      e = Event.new("something_else", %{})

      assert {:ok, %VaultEvent{address: nil, data: %Event{type: "something_else"}}} =
               Events.parse(e)
    end
  end
end
