defmodule Rujira.Brune.PoolTest do
  @moduledoc """
  `list/1` reads the deployment registry and each pool's config through
  `Rujira.Cache`, whose stores and head are global, so this case runs sync and
  starts from an empty cache.
  """
  use Rujira.Test.CacheCase, async: false

  alias Cosmos.Bank.V1beta1.QueryDenomMetadataRequest
  alias Rujira.Brune.Pool
  alias Rujira.Brune.Pool.Range
  alias Rujira.Test.MockNode
  alias Thorchain.Types.ContractInfo
  alias Thorchain.Types.QueryContractInfosRequest

  setup do
    MockNode.expect(fn %QueryDenomMetadataRequest{denom: denom} -> no_denom_metadata(denom) end)
  end

  defp expect_config do
    MockNode.expect(fn
      %{"config" => %{}} -> MockNode.ok(config())
      %QueryDenomMetadataRequest{denom: denom} -> no_denom_metadata(denom)
    end)
  end

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
      expect_config()

      assert {:ok, %Pool{address: "thor1pool"}} = Pool.get("thor1pool")
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
    test "round-trips on the pool's id" do
      expect_config()

      assert {:ok, %Pool{id: "thor1pool"} = pool} = Pool.get("thor1pool")

      expect_config()

      assert {:ok, ^pool} = Pool.from_id(pool.id)
    end

    test "a well-formed id with no contract behind it is not_found" do
      MockNode.expect(fn %{"config" => %{}} ->
        {:error, %GRPC.RPCError{status: 2, message: "codespace wasm code 22: no such contract"}}
      end)

      assert {:error, :not_found} = Pool.from_id("thor1missing")
    end
  end

  defp info(address),
    do: %ContractInfo{address: address, contract: "rujira-brune", version: "1"}

  # A token-factory denom's asset comes from the chain's metadata for it. These
  # fixtures are denoms the node holds none for, which is what names them here.
  defp no_denom_metadata(denom),
    do: {:error, %GRPC.RPCError{status: 5, message: "client metadata for denom #{denom}"}}
end
