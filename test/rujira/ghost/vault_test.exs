defmodule Rujira.Ghost.VaultTest do
  use ExUnit.Case, async: true

  alias Rujira.Ghost.Vault
  alias Rujira.Ghost.Vault.Interest

  describe "new/1" do
    test "parses vault config including the interest curve" do
      assert {:ok,
              %Vault{
                id: "thor1vault",
                address: "thor1vault",
                denom: "btc",
                receipt_denom: "x/ghost-vault/btc",
                fee_address: "thor1fee",
                fee: fee,
                interest: %Interest{} = interest
              }} =
               Vault.new(%{
                 "address" => "thor1vault",
                 "denom" => "btc",
                 "fee" => "0.1",
                 "fee_address" => "thor1fee",
                 "interest" => %{
                   "target_utilization" => "0.8",
                   "base_rate" => "0",
                   "step1" => "1",
                   "step2" => "2"
                 }
               })

      assert Decimal.equal?(fee, Decimal.new("0.1"))
      assert Decimal.equal?(interest.target_utilization, Decimal.new("0.8"))
      assert Decimal.equal?(interest.step2, Decimal.new("2"))
    end

    test "errors on missing fields" do
      assert {:error, :invalid_attrs} = Vault.new(%{})
    end
  end
end
