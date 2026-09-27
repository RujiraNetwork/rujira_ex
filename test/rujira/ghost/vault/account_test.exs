defmodule Rujira.Ghost.Vault.AccountTest do
  use ExUnit.Case, async: true

  alias Cosmos.Bank.V1beta1.QueryBalanceRequest
  alias Cosmos.Bank.V1beta1.QueryBalanceResponse
  alias Cosmos.Base.V1beta1.Coin
  alias Rujira.Ghost.Vault
  alias Rujira.Ghost.Vault.Account
  alias Rujira.Ghost.Vault.Status
  alias Rujira.Test.MockNode

  defp vault do
    %Vault{address: "thor1vault", denom: "btc", receipt_denom: "x/ghost-vault/btc"}
  end

  defp loaded_vault do
    %Vault{
      vault()
      | status: %Status{deposit_pool: %Status.DepositPool{ratio: Decimal.new("1.5")}}
    }
  end

  describe "new/3" do
    test "holds the shares the account was read with" do
      assert %Account{
               id: "thor1vault/thor1owner",
               account: "thor1owner",
               shares: 100
             } = Account.new(loaded_vault(), "thor1owner", 100)
    end
  end

  describe "load/3" do
    test "is the receipt-token balance and nothing else - no vault status" do
      MockNode.expect(fn %QueryBalanceRequest{
                           address: "thor1owner",
                           denom: "x/ghost-vault/btc"
                         } ->
        {:ok, %QueryBalanceResponse{balance: %Coin{denom: "x/ghost-vault/btc", amount: "100"}}}
      end)

      assert {:ok, %Account{id: "thor1vault/thor1owner", shares: 100}} =
               Account.load(vault(), "thor1owner")
    end

    test "hands back the balance error rather than an empty position" do
      MockNode.expect(fn %QueryBalanceRequest{} ->
        {:error, %GRPC.RPCError{status: 3, message: "boom"}}
      end)

      assert {:error, %GRPC.RPCError{status: 3}} = Account.load(vault(), "thor1owner")
    end
  end

  describe "value/2" do
    test "values the shares at the deposit-pool ratio" do
      account = Account.new(loaded_vault(), "thor1owner", 100)

      assert {:ok, 150} = Account.value(account, loaded_vault())
    end

    test "is zero for an account that holds no shares" do
      account = Account.new(loaded_vault(), "thor1owner", 0)

      assert {:ok, 0} = Account.value(account, loaded_vault())
    end

    test "needs the vault's status" do
      account = Account.new(vault(), "thor1owner", 100)

      assert {:error, :not_loaded} = Account.value(account, vault())
    end
  end
end
