defmodule Rujira.Staking.PoolTest do
  @moduledoc """
  `list/1` reads the deployment registry and each pool's config through
  `Rujira.Cache`, whose stores and head are global, so this case runs sync and
  starts from an empty cache.
  """
  use Rujira.Test.CacheCase, async: false

  alias Cosmos.Bank.V1beta1.QueryDenomMetadataRequest
  alias Rujira.Assets.Asset
  alias Rujira.Staking.Pool
  alias Rujira.Staking.Pool.RevenueConverter
  alias Rujira.Test.MockNode
  alias Thorchain.Types.ContractInfo
  alias Thorchain.Types.QueryContractInfosRequest

  setup do
    MockNode.expect(fn %QueryDenomMetadataRequest{denom: denom} -> no_denom_metadata(denom) end)
  end

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

  describe "list/1" do
    test "the head moving mid fan-out does not split the list across heights" do
      parent = self()
      pinned = default_head()

      MockNode.expect(fn
        %QueryContractInfosRequest{} ->
          {:ok, %{infos: [info("thor1poola"), info("thor1poolb")]}}

        %QueryDenomMetadataRequest{denom: denom} ->
          no_denom_metadata(denom)

        %{"config" => _} ->
          # `MockNode.query/3` posts `{:mock_node, request, opts}` to the leg's
          # own Task mailbox, so the leg forwards the height it was read at.
          receive do
            {:mock_node, _request, opts} ->
              send(parent, {:leg_height, get_in(opts, [:metadata, "x-cosmos-block-height"])})
          end

          # The head moves while the fan-out is still running. One item at a
          # time, so the second leg is read after the move.
          set_head(pinned + 1)
          MockNode.ok(config())
      end)

      assert {:ok, [_, _]} = Pool.list(fan_out: [max_concurrency: 1])

      expected = Integer.to_string(pinned)
      assert_received {:leg_height, ^expected}
      assert_received {:leg_height, ^expected}
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

  defp info(address),
    do: %ContractInfo{address: address, contract: "rujira-staking", version: "1"}

  # A vault/pool receipt is a token-factory denom, so building one reads the
  # chain's metadata for it. These fixtures are denoms the node holds none for,
  # which is what names them here.
  defp no_denom_metadata(denom),
    do: {:error, %GRPC.RPCError{status: 5, message: "client metadata for denom #{denom}"}}
end
