defmodule Rujira.Ghost.Vault.StatusTest do
  @moduledoc """
  `query/2` reads through `Rujira.Cache`, whose stores and head are global, so
  this case runs sync and starts from an empty cache.
  """
  use Rujira.Test.CacheCase, async: false

  alias Rujira.Ghost.Vault.Status
  alias Rujira.Test.MockNode

  describe "new/1" do
    test "parses status with nested debt/deposit pools and a ns timestamp" do
      assert {:ok, %Status{debt_pool: debt, deposit_pool: deposit} = status} =
               Status.new(%{
                 "last_updated" => "1700000000000000000",
                 "utilization_ratio" => "0.5",
                 "debt_rate" => "0.12",
                 "lend_rate" => "0.06",
                 "debt_pool" => %{"size" => "1000", "shares" => "900.5", "ratio" => "1.1"},
                 "deposit_pool" => %{"size" => "2000", "shares" => "2000", "ratio" => "1.0"}
               })

      assert DateTime.to_unix(status.last_updated, :nanosecond) == 1_700_000_000_000_000_000
      assert Decimal.equal?(status.utilization_ratio, Decimal.new("0.5"))
      assert %Status.DebtPool{size: 1000} = debt
      assert Decimal.equal?(debt.shares, Decimal.new("900.5"))
      assert %Status.DepositPool{size: 2000, shares: 2000} = deposit
    end

    test "errors on missing fields" do
      assert {:error, :invalid_attrs} = Status.new(%{})
    end
  end

  describe "query/2" do
    test "a second read at the same height is served from the cache" do
      MockNode.expect(fn %{"status" => %{}} -> MockNode.ok(%{"a" => 1}) end)

      assert {:ok, %{"a" => 1}} = Status.query("thor1vault", height: default_head())
      assert {:ok, %{"a" => 1}} = Status.query("thor1vault", height: default_head())

      assert_received {:mock_node, _, _}
      refute_received {:mock_node, _, _}
    end

    test "a different height fetches again" do
      MockNode.expect(fn %{"status" => %{}} -> MockNode.ok(%{"a" => 1}) end)

      assert {:ok, %{"a" => 1}} = Status.query("thor1vault", height: default_head())
      assert {:ok, %{"a" => 1}} = Status.query("thor1vault", height: default_head() + 1)

      assert_received {:mock_node, _, _}
      assert_received {:mock_node, _, _}
    end

    test "an error is never cached, so the next read retries it" do
      MockNode.expect(fn %{"status" => %{}} ->
        case Process.get(:calls, 0) do
          0 ->
            Process.put(:calls, 1)
            {:error, %GRPC.RPCError{status: 13, message: "boom"}}

          _ ->
            MockNode.ok(%{"a" => 1})
        end
      end)

      assert {:error, %GRPC.RPCError{status: 13}} =
               Status.query("thor1vault", height: default_head())

      assert {:ok, %{"a" => 1}} = Status.query("thor1vault", height: default_head())
    end
  end
end
