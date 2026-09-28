defmodule Rujira.Ghost.VaultTest do
  use ExUnit.Case, async: true

  alias Cosmos.Bank.V1beta1.QueryDenomMetadataRequest
  alias Rujira.Ghost.Vault
  alias Rujira.Ghost.Vault.Interest
  alias Rujira.Test.MockNode

  setup do
    MockNode.expect(fn %QueryDenomMetadataRequest{denom: denom} -> no_denom_metadata(denom) end)
  end

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
      MockNode.expect(fn
        %QueryDenomMetadataRequest{denom: denom} ->
          no_denom_metadata(denom)

        %{"config" => _} ->
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

      assert {:error, :not_found} = Vault.from_id("thor1missing", height: 12_345)
    end
  end

  # A token-factory denom's asset comes from the chain's metadata for it. These
  # fixtures are denoms the node holds none for, which is what names them here.
  defp no_denom_metadata(denom),
    do: {:error, %GRPC.RPCError{status: 5, message: "client metadata for denom #{denom}"}}
end
