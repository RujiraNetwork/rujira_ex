defmodule Rujira.Ghost.Vault.DelegateTest do
  @moduledoc """
  `query/4` reads through `Rujira.Cache`, whose stores and head are global, so
  this case runs sync and starts from an empty cache.
  """
  use Rujira.Test.CacheCase, async: false

  alias Rujira.Ghost.Vault.Borrower
  alias Rujira.Ghost.Vault.Delegate
  alias Rujira.Test.MockNode

  describe "new/1" do
    test "parses a delegate with its nested borrower" do
      assert {:ok,
              %Delegate{address: "thor1d", current: 50, borrower: %Borrower{address: "thor1b"}} =
                delegate} =
               Delegate.new(%{
                 "addr" => "thor1d",
                 "current" => "50",
                 "shares" => "49.5",
                 "borrower" => %{
                   "addr" => "thor1b",
                   "denom" => "btc-btc",
                   "limit" => "500",
                   "current" => "100",
                   "shares" => "100",
                   "available" => "400"
                 }
               })

      assert Decimal.equal?(delegate.shares, Decimal.new("49.5"))
    end

    test "errors on missing fields" do
      assert {:error, :invalid_attrs} = Delegate.new(%{})
    end
  end

  describe "query/4" do
    test "a second read at the same height is served from the cache" do
      MockNode.expect(fn %{"delegate" => %{"borrower" => "thor1b", "addr" => "thor1d"}} ->
        MockNode.ok(%{"a" => 1})
      end)

      assert {:ok, %{"a" => 1}} =
               Delegate.query("thor1v", "thor1b", "thor1d", height: default_head())

      assert {:ok, %{"a" => 1}} =
               Delegate.query("thor1v", "thor1b", "thor1d", height: default_head())

      assert_received {:mock_node, _, _}
      refute_received {:mock_node, _, _}
    end
  end
end
