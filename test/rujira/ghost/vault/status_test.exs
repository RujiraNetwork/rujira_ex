defmodule Rujira.Ghost.Vault.StatusTest do
  use ExUnit.Case, async: true

  alias Rujira.Ghost.Vault.Status

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
end
