defmodule Rujira.Ghost.VaultTest do
  use ExUnit.Case, async: true

  alias Rujira.Ghost.Vault
  alias Rujira.Ghost.Vault.Interest
  alias Rujira.Test.MockNode

  describe "new/1" do
    test "parses vault config including the interest curve" do
      assert {:ok,
              %Vault{
                id: "thor1vault",
                address: "thor1vault",
                asset: asset,
                receipt_asset: receipt_asset,
                fee_address: "thor1fee",
                fee: fee,
                interest: %Interest{} = interest
              }} =
               Vault.new(%{
                 "address" => "thor1vault",
                 "denom" => "btc-btc",
                 "fee" => "0.1",
                 "fee_address" => "thor1fee",
                 "interest" => %{
                   "target_utilization" => "0.8",
                   "base_rate" => "0",
                   "step1" => "1",
                   "step2" => "2"
                 }
               })

      assert asset.id == "BTC-BTC"
      assert receipt_asset.id == "x/ghost-vault/btc-btc"
      assert Decimal.equal?(fee, Decimal.new("0.1"))
      assert Decimal.equal?(interest.target_utilization, Decimal.new("0.8"))
      assert Decimal.equal?(interest.step2, Decimal.new("2"))
    end

    test "errors on missing fields" do
      assert {:error, :invalid_attrs} = Vault.new(%{})
    end

    test "an unrecognised denom is an error" do
      assert {:error, :invalid_denom} =
               Vault.new(%{
                 "address" => "thor1vault",
                 "denom" => "not a denom",
                 "fee" => "0.1",
                 "fee_address" => "thor1fee",
                 "interest" => %{
                   "target_utilization" => "0.8",
                   "base_rate" => "0",
                   "step1" => "1",
                   "step2" => "2"
                 }
               })
    end
  end

  describe "from_id/2" do
    test "resolves a vault by its address, which is its id" do
      MockNode.expect(fn %{"config" => _} ->
        MockNode.ok(%{
          "address" => "thor1vault",
          "denom" => "btc-btc",
          "fee" => "0.1",
          "fee_address" => "thor1fee",
          "interest" => %{
            "target_utilization" => "0.8",
            "base_rate" => "0",
            "step1" => "1",
            "step2" => "2"
          }
        })
      end)

      assert {:ok, %Vault{id: "thor1vault", address: "thor1vault"}} =
               Vault.from_id("thor1vault", height: 12_345)
    end

    test "a well-formed id with no contract behind it is not_found" do
      MockNode.expect(fn %{"config" => %{}} ->
        {:error, %GRPC.RPCError{status: 2, message: "codespace wasm code 22: no such contract"}}
      end)

      assert {:error, :not_found} = Vault.from_id("thor1missing")
    end
  end
end
