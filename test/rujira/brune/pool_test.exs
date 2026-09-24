defmodule Rujira.Brune.PoolTest do
  use ExUnit.Case, async: true

  alias Rujira.Brune.Pool
  alias Rujira.Brune.Pool.Range
  alias Rujira.Test.MockNode

  defp config(extra \\ %{}) do
    Map.merge(
      %{
        "address" => "thor1pool",
        "fin_contract" => "thor1fin",
        "stake_contract" => "thor1stake",
        "token_id" => "rbrune",
        "target_utilization" => "0.8",
        "min_node_fee" => "0.01",
        "range" => %{"high" => "1.5", "low" => "0.5", "skew" => "-0.1", "step" => "0.05"},
        "permissionless" => true,
        "revenue_smear" => 100,
        "quarantine" => %{"height" => 1000},
        "nodes_cache_ttl" => 60,
        "max_bond" => "1000000000",
        "max_effective_bond" => "500000000",
        "mint_cap" => "2000000000"
      },
      extra
    )
  end

  describe "new/1" do
    test "parses full config, including negative skew" do
      assert {:ok,
              %Pool{
                id: "thor1pool",
                address: "thor1pool",
                fin_contract: "thor1fin",
                stake_contract: "thor1stake",
                token: %Rujira.Assets.Asset{id: "x/rbrune"},
                permissionless: true,
                revenue_smear: 100,
                quarantine: {:height, 1000},
                nodes_cache_ttl: 60,
                max_bond: 1_000_000_000,
                max_effective_bond: 500_000_000,
                mint_cap: 2_000_000_000,
                range: %Range{} = range,
                target_utilization: target_utilization,
                min_node_fee: min_node_fee,
                state: :not_loaded
              }} = Pool.new(config())

      assert Decimal.equal?(target_utilization, Decimal.new("0.8"))
      assert Decimal.equal?(min_node_fee, Decimal.new("0.01"))
      assert Decimal.equal?(range.high, Decimal.new("1.5"))
      assert Decimal.equal?(range.low, Decimal.new("0.5"))
      assert Decimal.equal?(range.skew, Decimal.new("-0.1"))
      assert Decimal.equal?(range.step, Decimal.new("0.05"))
    end

    test "parses a time-based quarantine" do
      assert {:ok, %Pool{quarantine: {:time, 1_700_000_000}}} =
               Pool.new(config(%{"quarantine" => %{"time" => 1_700_000_000}}))
    end

    test "errors on missing fields" do
      assert {:error, :invalid_attrs} = Pool.new(%{})
    end

    test "errors on an unrecognised quarantine shape" do
      assert {:error, :invalid_attrs} = Pool.new(config(%{"quarantine" => %{}}))
    end
  end

  describe "get/1" do
    test "queries config and constructs the pool" do
      MockNode.expect(fn %{"config" => %{}} -> MockNode.ok(config()) end)

      assert {:ok, %Pool{address: "thor1pool"}} = Pool.get("thor1pool")
    end
  end
end
