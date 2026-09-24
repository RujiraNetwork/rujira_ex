defmodule Rujira.Staking.Pool.AccountTest do
  use ExUnit.Case, async: true

  alias Cosmos.Bank.V1beta1.QueryBalanceRequest
  alias Cosmos.Bank.V1beta1.QueryBalanceResponse
  alias Cosmos.Base.V1beta1.Coin
  alias Rujira.Assets.Asset
  alias Rujira.Staking.Pool
  alias Rujira.Staking.Pool.Account
  alias Rujira.Staking.Pool.Status
  alias Rujira.Test.MockNode

  defp loaded_pool(fee \\ Decimal.new(0)) do
    %Pool{
      address: "thor1pool",
      receipt_asset: %Asset{id: "x/staking-rune"},
      fee: fee,
      status: %Status{
        account_bond: 1000,
        liquid_bond_shares: 1000,
        liquid_bond_size: 1100,
        undistributed_revenue: 101
      }
    }
  end

  setup do
    Memoize.invalidate(Account)
    on_exit(fn -> Memoize.invalidate(Account) end)
    :ok
  end

  describe "load/2" do
    test "computes pending revenue share and liquid size with a fee" do
      MockNode.expect(fn
        %{"account" => %{"addr" => "thor1owner"}} ->
          MockNode.ok(%{"addr" => "thor1owner", "bonded" => "200", "pending_revenue" => "5"})

        %QueryBalanceRequest{address: "thor1owner", denom: "x/staking-rune"} ->
          {:ok, %QueryBalanceResponse{balance: %Coin{denom: "x/staking-rune", amount: "100"}}}
      end)

      pool = loaded_pool(Decimal.new("0.1"))

      assert {:ok,
              %Account{
                id: "thor1pool/thor1owner",
                pool: "thor1pool",
                owner: "thor1owner",
                bonded: 200,
                pending_revenue: 13,
                liquid_shares: 100,
                liquid_size: 110
              }} = Account.load(pool, "thor1owner")
    end

    test "loads the pool status first when not_loaded" do
      MockNode.expect(fn
        %{"status" => %{}} ->
          MockNode.ok(%{
            "account_bond" => "0",
            "assigned_revenue" => "0",
            "liquid_bond_shares" => "0",
            "liquid_bond_size" => "0",
            "undistributed_revenue" => "0"
          })

        %{"account" => %{"addr" => "thor1owner"}} ->
          MockNode.ok(%{"addr" => "thor1owner", "bonded" => "0", "pending_revenue" => "0"})

        %QueryBalanceRequest{} ->
          {:ok, %QueryBalanceResponse{balance: nil}}
      end)

      assert {:ok, %Account{bonded: 0, pending_revenue: 0, liquid_shares: 0, liquid_size: 0}} =
               Account.load(
                 %Pool{address: "thor1pool", receipt_asset: %Asset{id: "x/staking-rune"}},
                 "thor1owner"
               )
    end

    test "falls back to a zero account on NotFound" do
      MockNode.expect(fn
        %{"account" => %{"addr" => "thor1owner"}} ->
          {:error, %GRPC.RPCError{status: 2, message: "NotFound: query wasm contract failed"}}

        %QueryBalanceRequest{} ->
          {:ok, %QueryBalanceResponse{balance: nil}}
      end)

      assert {:ok, %Account{bonded: 0, pending_revenue: 0}} =
               Account.load(loaded_pool(), "thor1owner")
    end

    test "propagates other errors" do
      MockNode.expect(fn
        %{"account" => %{"addr" => "thor1owner"}} ->
          {:error, %GRPC.RPCError{status: 3, message: "boom"}}
      end)

      assert {:error, %GRPC.RPCError{status: 3}} = Account.load(loaded_pool(), "thor1owner")
    end
  end

  describe "from_id/1" do
    test "errors on a malformed id" do
      assert {:error, :invalid_id} = Account.from_id("thor1pool")
    end
  end
end
