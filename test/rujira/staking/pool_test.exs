defmodule Rujira.Staking.PoolTest do
  use ExUnit.Case, async: true

  alias Rujira.Assets.Asset
  alias Rujira.Staking.Pool
  alias Rujira.Staking.Pool.RevenueConverter
  alias Rujira.Test.MockNode

  defp config(extra \\ %{}) do
    Map.merge(
      %{
        "address" => "thor1pool",
        "bond_denom" => "x/ruji",
        "revenue_denom" => "btc-btc",
        "revenue_converter" => ["thor1converter", "eyJmb28iOiJiYXIifQ==", "1000000"],
        "fee" => nil
      },
      extra
    )
  end

  describe "new/1" do
    test "parses pool config with no fee" do
      assert {:ok,
              %Pool{
                id: "thor1pool",
                address: "thor1pool",
                bond_asset: %Asset{id: "THOR.RUJI"},
                revenue_asset: %Asset{id: "BTC-BTC"},
                receipt_asset: %Asset{id: "x/staking-x/ruji"},
                fee: nil,
                fee_address: nil,
                revenue_converter: %RevenueConverter{
                  contract: "thor1converter",
                  msg: "eyJmb28iOiJiYXIifQ==",
                  limit: 1_000_000
                },
                status: :not_loaded
              }} = Pool.new(config())
    end

    test "parses pool config with a fee" do
      assert {:ok, %Pool{fee: fee, fee_address: "thor1fee"}} =
               Pool.new(config(%{"fee" => ["0.05", "thor1fee"]}))

      assert Decimal.equal?(fee, Decimal.new("0.05"))
    end

    test "errors on missing fields" do
      assert {:error, :invalid_attrs} = Pool.new(%{})
    end

    test "errors on a malformed revenue converter" do
      assert {:error, :invalid_attrs} =
               Pool.new(config(%{"revenue_converter" => ["thor1converter"]}))
    end

    test "errors on an unresolvable bond denom" do
      assert {:error, :invalid_denom} = Pool.new(config(%{"bond_denom" => "badbond"}))
    end
  end

  describe "from_id/2" do
    test "a well-formed id with no contract behind it is not_found" do
      MockNode.expect(fn %{"config" => %{}} ->
        {:error, %GRPC.RPCError{status: 2, message: "codespace wasm code 22: no such contract"}}
      end)

      assert {:error, :not_found} = Pool.from_id("thor1missing")
    end
  end
end
