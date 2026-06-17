defmodule Rujira.Ghost.Vault.BorrowerTest do
  use ExUnit.Case, async: true

  alias Rujira.Ghost.Vault.Borrower

  describe "new/1" do
    test "parses a borrower response" do
      assert {:ok,
              %Borrower{
                address: "thor1b",
                denom: "btc",
                limit: 500,
                current: 100,
                available: 400,
                shares: shares
              }} =
               Borrower.new(%{
                 "addr" => "thor1b",
                 "denom" => "btc",
                 "limit" => "500",
                 "current" => "100",
                 "shares" => "100.5",
                 "available" => "400"
               })

      assert Decimal.equal?(shares, Decimal.new("100.5"))
    end

    test "errors on missing fields" do
      assert {:error, :invalid_attrs} = Borrower.new(%{})
    end
  end
end
