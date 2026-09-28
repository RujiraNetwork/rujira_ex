defmodule Rujira.Staking.Pool.AccountTest do
  @moduledoc """
  `load/2` reads through `Rujira.Cache`, whose stores and head are global, so
  this case runs sync and starts from an empty cache.
  """
  use Rujira.Test.CacheCase, async: false

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

  defp pool do
    %Pool{address: "thor1pool", receipt_asset: %Asset{id: "x/staking-rune"}}
  end

  describe "load/2" do
    test "is the contract's account and nothing else - no status, no bank balance" do
      MockNode.expect(fn %{"account" => %{"addr" => "thor1owner"}} ->
        MockNode.ok(%{"addr" => "thor1owner", "bonded" => "200", "pending_revenue" => "5"})
      end)

      assert {:ok,
              %Account{
                id: "thor1pool/thor1owner",
                pool: "thor1pool",
                owner: "thor1owner",
                bonded: 200,
                pending_revenue: 5
              }} = Account.load(pool(), "thor1owner")
    end

    test "reads the account of a pool whose status is loaded without re-reading it" do
      MockNode.expect(fn %{"account" => %{"addr" => "thor1owner"}} ->
        MockNode.ok(%{"addr" => "thor1owner", "bonded" => "200", "pending_revenue" => "5"})
      end)

      assert {:ok, %Account{bonded: 200, pending_revenue: 5}} =
               Account.load(loaded_pool(), "thor1owner")
    end

    test "an owner that has never bonded is an empty account, not a not-found" do
      MockNode.expect(fn %{"account" => %{"addr" => "thor1owner"}} -> never_bonded() end)

      assert {:ok,
              %Account{
                id: "thor1pool/thor1owner",
                pool: "thor1pool",
                owner: "thor1owner",
                bonded: 0,
                pending_revenue: 0
              }} = Account.load(pool(), "thor1owner")
    end

    test "the empty account is cached, so a second read does not re-ask the node" do
      MockNode.expect(fn %{"account" => %{"addr" => "thor1owner"}} -> never_bonded() end)

      assert {:ok, %Account{bonded: 0}} = Account.load(pool(), "thor1owner")
      assert {:ok, %Account{bonded: 0}} = Account.load(pool(), "thor1owner")

      assert_received {:mock_node, _, _}
      refute_received {:mock_node, _, _}
    end

    test "propagates other errors" do
      MockNode.expect(fn %{"account" => %{"addr" => "thor1owner"}} ->
        {:error, %GRPC.RPCError{status: 3, message: "boom"}}
      end)

      assert {:error, %GRPC.RPCError{status: 3}} = Account.load(pool(), "thor1owner")
    end

    test "a second read at the same height is served from the cache" do
      MockNode.expect(fn %{"account" => %{"addr" => "thor1owner"}} ->
        MockNode.ok(%{"addr" => "thor1owner", "bonded" => "200", "pending_revenue" => "5"})
      end)

      assert {:ok, %Account{}} = Account.load(pool(), "thor1owner", height: default_head())
      assert {:ok, %Account{}} = Account.load(pool(), "thor1owner", height: default_head())

      assert_received {:mock_node, _, _}
      refute_received {:mock_node, _, _}
    end
  end

  # The contract loads the account bare, so an owner it holds no record for comes
  # back as a `StdError::NotFound` rather than an empty response.
  defp never_bonded do
    {:error,
     %GRPC.RPCError{
       status: 2,
       message:
         "type: rujira_rs::account_pool::AccountPoolAccount; key: [00] not found: " <>
           "query wasm contract failed"
     }}
  end

  describe "from_id/1" do
    test "errors on a malformed id" do
      assert {:error, :invalid_id} = Account.from_id("thor1pool")
    end
  end

  describe "revenue_share/2" do
    test "mirrors the contract's distribute(), net of the pool fee" do
      account = Account.new(loaded_pool(), "thor1owner", 200, 5)

      assert {:ok, 8} = Account.revenue_share(account, loaded_pool(Decimal.new("0.1")))
    end

    test "is zero for an account that has nothing bonded" do
      account = Account.new(loaded_pool(), "thor1owner", 0, 0)

      assert {:ok, 0} = Account.revenue_share(account, loaded_pool())
    end

    test "needs the pool's status" do
      account = Account.new(pool(), "thor1owner", 200, 5)

      assert {:error, :not_loaded} = Account.revenue_share(account, pool())
    end

    test "treats a nil pool fee as no fee deduction" do
      account = Account.new(loaded_pool(), "thor1owner", 200, 5)

      assert {:ok, 9} = Account.revenue_share(account, loaded_pool(nil))
    end
  end

  describe "liquid_size/2" do
    test "values receipt tokens at the pool's liquid bond ratio" do
      assert {:ok, 110} = Account.liquid_size(100, loaded_pool())
    end

    test "is zero while the pool has issued no liquid shares" do
      pool = %Pool{loaded_pool() | status: %Status{liquid_bond_shares: 0, liquid_bond_size: 0}}

      assert {:ok, 0} = Account.liquid_size(100, pool)
    end

    test "needs the pool's status" do
      assert {:error, :not_loaded} = Account.liquid_size(100, pool())
    end
  end
end
