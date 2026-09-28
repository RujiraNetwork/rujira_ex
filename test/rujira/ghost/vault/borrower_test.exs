defmodule Rujira.Ghost.Vault.BorrowerTest do
  @moduledoc """
  `query/3` and `query_borrowers/2` read through `Rujira.Cache`, whose stores
  and head are global, so this case runs sync and starts from an empty cache.
  """
  use Rujira.Test.CacheCase, async: false

  alias Rujira.Ghost.Vault.Borrower
  alias Rujira.Test.MockNode

  describe "new/1" do
    test "parses a borrower response" do
      assert {:ok,
              %Borrower{
                address: "thor1b",
                asset: asset,
                limit: 500,
                current: 100,
                available: 400,
                shares: shares
              }} =
               Borrower.new(%{
                 "addr" => "thor1b",
                 "denom" => "btc-btc",
                 "limit" => "500",
                 "current" => "100",
                 "shares" => "100.5",
                 "available" => "400"
               })

      assert asset.id == "BTC-BTC"
      assert Decimal.equal?(shares, Decimal.new("100.5"))
    end

    test "errors on missing fields" do
      assert {:error, :invalid_attrs} = Borrower.new(%{})
    end

    test "an unrecognised denom is an error" do
      assert {:error, :invalid_denom} =
               Borrower.new(%{
                 "addr" => "thor1b",
                 "denom" => "not a denom",
                 "limit" => "500",
                 "current" => "100",
                 "shares" => "100.5",
                 "available" => "400"
               })
    end
  end

  describe "query/3" do
    test "a second read at the same height is served from the cache" do
      MockNode.expect(fn %{"borrower" => %{"addr" => "thor1b"}} -> MockNode.ok(%{"a" => 1}) end)

      assert {:ok, %{"a" => 1}} = Borrower.query("thor1v", "thor1b", height: default_head())
      assert {:ok, %{"a" => 1}} = Borrower.query("thor1v", "thor1b", height: default_head())

      assert_received {:mock_node, _, _}
      refute_received {:mock_node, _, _}
    end
  end

  describe "query_borrowers/2" do
    test "a second read at the same height is served from the cache" do
      MockNode.expect(fn %{"borrowers" => _} -> MockNode.ok(%{"borrowers" => []}) end)

      assert {:ok, []} = Borrower.query_borrowers("thor1v", height: default_head())
      assert {:ok, []} = Borrower.query_borrowers("thor1v", height: default_head())

      assert_received {:mock_node, _, _}
      refute_received {:mock_node, _, _}
    end
  end
end
