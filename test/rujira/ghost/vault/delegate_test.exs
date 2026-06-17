defmodule Rujira.Ghost.Vault.DelegateTest do
  use ExUnit.Case, async: true

  alias Rujira.Ghost.Vault.Borrower
  alias Rujira.Ghost.Vault.Delegate

  describe "new/1" do
    test "parses a delegate with its nested borrower" do
      assert {:ok,
              %Delegate{address: "thor1d", current: 50, borrower: %Borrower{address: "thor1b"}} =
                delegate} =
               Delegate.new(%{
                 "addr" => "thor1d",
                 "current" => "50",
                 "shares" => "49.5",
                 "borrower" => %{
                   "addr" => "thor1b",
                   "denom" => "btc",
                   "limit" => "500",
                   "current" => "100",
                   "shares" => "100",
                   "available" => "400"
                 }
               })

      assert Decimal.equal?(delegate.shares, Decimal.new("49.5"))
    end

    test "errors on missing fields" do
      assert {:error, :invalid_attrs} = Delegate.new(%{})
    end
  end
end
