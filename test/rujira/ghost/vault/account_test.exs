defmodule Rujira.Ghost.Vault.AccountTest do
  use ExUnit.Case, async: true

  alias Rujira.Ghost.Vault
  alias Rujira.Ghost.Vault.Account
  alias Rujira.Ghost.Vault.Status

  defp loaded_vault do
    %Vault{
      address: "thor1vault",
      denom: "btc",
      receipt_denom: "x/ghost-vault/btc",
      status: %Status{deposit_pool: %Status.DepositPool{ratio: Decimal.new("1.5")}}
    }
  end

  describe "new/3" do
    test "computes value from the deposit-pool ratio" do
      assert %Account{
               id: "thor1vault/thor1owner",
               account: "thor1owner",
               shares: 100,
               value: 150
             } = Account.new(loaded_vault(), "thor1owner", 100)
    end

    test "defaults to an empty position with zero shares and value" do
      assert %Account{shares: 0, value: 0} = Account.new(loaded_vault(), "thor1owner")
    end
  end
end
