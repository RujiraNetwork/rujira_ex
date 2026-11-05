defmodule Rujira.Ghost.VaultTest do
  # `list/1` reads Deployments and Contracts through `Rujira.Cache`, whose
  # stores are global, so this case runs sync and starts from an empty cache.
  use Rujira.Test.CacheCase, async: false

  alias Cosmos.Bank.V1beta1.QueryDenomMetadataRequest
  alias Cosmwasm.Wasm.V1.QuerySmartContractStateRequest
  alias Rujira.Ghost
  alias Rujira.Ghost.Vault
  alias Rujira.Ghost.Vault.Interest
  alias Rujira.Test.MockNode
  alias Thorchain.Types.ContractInfo
  alias Thorchain.Types.QueryContractInfosRequest

  @height 12_345

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

  describe "config shapes, through get/2" do
    test "V2 (1303d28 and later) carries fee and fee_address" do
      expect_configs(fn _address -> MockNode.ok(v2_config()) end)

      assert {:ok, %Vault{address: "thor1vault", fee_address: "thor1fee", fee: fee} = vault} =
               Ghost.get_vault("thor1vault", height: @height)

      assert Decimal.equal?(fee, Decimal.new("0.1"))
      assert vault.asset.id == "BTC-BTC"
      assert Decimal.equal?(vault.interest.step1, Decimal.new("1"))
    end

    test "V1 (v1.0.0 to v1.0.5) has no fee, so fee and fee_address are nil" do
      expect_configs(fn _address -> MockNode.ok(v1_config()) end)

      assert {:ok, %Vault{address: "thor1vault", fee: nil, fee_address: nil} = vault} =
               Ghost.get_vault("thor1vault", height: @height)

      assert vault.asset.id == "BTC-BTC"
      assert vault.receipt_asset.id == "x/ghost-vault/btc-btc"
      assert Decimal.equal?(vault.interest.target_utilization, Decimal.new("0.8"))
    end

    test "V0 (v0.x) has no config query, and its contract error comes back unchanged" do
      expect_configs(fn _address -> v0_error() end)

      assert Ghost.get_vault("thor1vault", height: @height) == v0_error()
    end

    test "an unknown shape is invalid_attrs" do
      expect_configs(fn _address -> MockNode.ok(%{"denom" => "btc-btc"}) end)

      assert {:error, :invalid_attrs} = Ghost.get_vault("thor1vault", height: @height)
    end

    test "unknown extra keys are ignored" do
      expect_configs(fn _address -> MockNode.ok(Map.put(v2_config(), "new_key", 1)) end)

      assert {:ok, %Vault{fee_address: "thor1fee"}} =
               Ghost.get_vault("thor1vault", height: @height)
    end
  end

  describe "list/1 across shapes" do
    test "lists V1 and V2 vaults together" do
      expect_configs(
        fn
          "thor1vaultv1" -> MockNode.ok(v1_config())
          "thor1vaultv2" -> MockNode.ok(v2_config())
        end,
        ["thor1vaultv1", "thor1vaultv2"]
      )

      assert {:ok, vaults} = Ghost.list_vaults(height: @height)

      assert [
               %Vault{address: "thor1vaultv1", fee: nil, fee_address: nil},
               %Vault{address: "thor1vaultv2", fee_address: "thor1fee"}
             ] = Enum.sort_by(vaults, & &1.address)
    end

    test "a V0 vault fails the list as a whole with its contract error" do
      expect_configs(
        fn
          "thor1vaultv0" -> v0_error()
          "thor1vaultv2" -> MockNode.ok(v2_config())
        end,
        ["thor1vaultv0", "thor1vaultv2"]
      )

      assert Ghost.list_vaults(height: @height) == v0_error()
    end
  end

  # --- Fixtures ---

  # Scripts the registry (listing `addresses`) and each vault's `config` reply,
  # chosen by the queried contract's address. `MockNode.query/3` posts the raw
  # request to the querying process's own mailbox just before the script runs.
  defp expect_configs(reply, addresses \\ []) do
    MockNode.expect(fn
      %QueryContractInfosRequest{} ->
        {:ok, %{infos: Enum.map(addresses, &vault_info/1)}}

      %QueryDenomMetadataRequest{denom: denom} ->
        no_denom_metadata(denom)

      %{"config" => %{}} ->
        receive do
          {:mock_node, %QuerySmartContractStateRequest{address: address}, _opts} ->
            reply.(address)
        end
    end)
  end

  defp vault_info(address),
    do: %ContractInfo{address: address, contract: "rujira-ghost-vault", version: "1.0.6"}

  # The `config` response in `contracts/rujira-ghost-vault/schema/rujira-ghost-vault.json`
  # at upstream e099bac (Cargo 1.0.5): `denom` and `interest` only.
  defp v1_config do
    %{
      "denom" => "btc-btc",
      "interest" => %{
        "target_utilization" => "0.8",
        "base_rate" => "0",
        "step1" => "1",
        "step2" => "2"
      }
    }
  end

  # The same schema at upstream 1303d28, which adds `fee_address` and `fee`.
  defp v2_config, do: Map.merge(v1_config(), %{"fee" => "0.1", "fee_address" => "thor1fee"})

  # A v0.x vault's `QueryMsg` has no `config` variant (upstream 787e63b to
  # fbf80aa), so the contract rejects the query while parsing it.
  defp v0_error do
    {:error,
     %GRPC.RPCError{
       status: 2,
       message:
         "Error parsing into type rujira_rs::interfaces::ghost::vault::interface::QueryMsg: " <>
           "unknown variant `config`, expected one of `status`, `borrower`, `borrowers`: " <>
           "query wasm contract failed"
     }}
  end

  # A token-factory denom's asset comes from the chain's metadata for it. These
  # fixtures are denoms the node holds none for, which is what names them here.
  defp no_denom_metadata(denom),
    do: {:error, %GRPC.RPCError{status: 5, message: "client metadata for denom #{denom}"}}
end
