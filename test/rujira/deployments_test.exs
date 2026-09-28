defmodule Rujira.DeploymentsTest do
  @moduledoc """
  `contract_infos/1` is the module's one node read and is cached per
  `Rujira.Cache`; every other lookup derives from it. The cache is global, so
  this case runs sync and starts from an empty one.
  """
  use Rujira.Test.CacheCase, async: false

  alias Rujira.Deployments
  alias Rujira.Fin.Pair
  alias Rujira.Test.MockNode
  alias Rujira.ThorchainSwap.Strategy
  alias Thorchain.Types.ContractInfo
  alias Thorchain.Types.QueryContractInfosRequest

  defmodule CustomStrategy do
    @moduledoc false
    defstruct []
  end

  setup do
    original = Application.get_env(:rujira_ex, :protocol_modules)

    on_exit(fn ->
      if original do
        Application.put_env(:rujira_ex, :protocol_modules, original)
      else
        Application.delete_env(:rujira_ex, :protocol_modules)
      end
    end)

    :ok
  end

  describe "protocol_modules" do
    test "a consumer entry overrides a built-in default" do
      Application.put_env(:rujira_ex, :protocol_modules, %{
        "rujira-thorchain-swap" => CustomStrategy
      })

      MockNode.expect(fn %QueryContractInfosRequest{} ->
        {:ok,
         %{
           infos: [
             %ContractInfo{address: "thor1tswap", contract: "rujira-thorchain-swap", version: "1"}
           ]
         }}
      end)

      assert {:ok, [%{address: "thor1tswap", module: CustomStrategy}]} =
               Deployments.list_all_targets()
    end

    test "built-in defaults still resolve without a consumer override" do
      MockNode.expect(fn %QueryContractInfosRequest{} ->
        {:ok,
         %{
           infos: [
             %ContractInfo{
               address: "thor1tswap",
               contract: "rujira-thorchain-swap",
               version: "1"
             },
             %ContractInfo{address: "thor1fin", contract: "rujira-fin", version: "1"}
           ]
         }}
      end)

      assert {:ok, targets} = Deployments.list_all_targets()

      assert %{module: Strategy} = Enum.find(targets, &(&1.address == "thor1tswap"))
      assert %{module: Pair} = Enum.find(targets, &(&1.address == "thor1fin"))
    end

    test "rujira-revenue resolves to Rujira.Revenue.Converter by default" do
      MockNode.expect(fn %QueryContractInfosRequest{} ->
        {:ok,
         %{
           infos: [
             %ContractInfo{address: "thor1revenue", contract: "rujira-revenue", version: "1"}
           ]
         }}
      end)

      assert {:ok, [%{address: "thor1revenue", module: Rujira.Revenue.Converter}]} =
               Deployments.list_all_targets()
    end

    test "rujira-ghost-credit resolves to Rujira.Ghost.Credit by default" do
      MockNode.expect(fn %QueryContractInfosRequest{} ->
        {:ok,
         %{
           infos: [
             %ContractInfo{
               address: "thor1credit",
               contract: "rujira-ghost-credit",
               version: "1.0.4"
             }
           ]
         }}
      end)

      assert {:ok, [%{address: "thor1credit", module: Rujira.Ghost.Credit}]} =
               Deployments.list_all_targets()
    end
  end

  describe "get_target/1 and list_targets/1" do
    test "get_target/1 returns {:error, :not_found} for an unmatched module" do
      MockNode.expect(fn %QueryContractInfosRequest{} ->
        {:ok, %{infos: []}}
      end)

      assert {:error, :not_found} = Deployments.get_target(Pair)
    end

    test "get_target/1 returns {:ok, target} for a matched module" do
      MockNode.expect(fn %QueryContractInfosRequest{} ->
        {:ok,
         %{infos: [%ContractInfo{address: "thor1fin", contract: "rujira-fin", version: "1"}]}}
      end)

      assert {:ok, %{address: "thor1fin", module: Pair}} = Deployments.get_target(Pair)
    end

    test "from_id/1 returns the same target as the one it was resolved from" do
      MockNode.expect(fn %QueryContractInfosRequest{} ->
        {:ok,
         %{infos: [%ContractInfo{address: "thor1fin", contract: "rujira-fin", version: "1"}]}}
      end)

      assert {:ok, %{address: "thor1fin", module: Pair} = target} = Deployments.get_target(Pair)
      assert {:ok, ^target} = Deployments.from_id(target.id)
    end

    test "get_target/1 propagates an underlying query error rather than :not_found" do
      MockNode.expect(fn %QueryContractInfosRequest{} -> {:error, :boom} end)

      assert {:error, :boom} = Deployments.get_target(Pair)
    end

    test "list_targets/1 returns {:ok, []} when legitimately none match" do
      MockNode.expect(fn %QueryContractInfosRequest{} ->
        {:ok,
         %{infos: [%ContractInfo{address: "thor1fin", contract: "rujira-fin", version: "1"}]}}
      end)

      assert {:ok, []} = Deployments.list_targets(Strategy)
    end

    test "list_targets/1 propagates an underlying query error rather than []" do
      MockNode.expect(fn %QueryContractInfosRequest{} -> {:error, :boom} end)

      assert {:error, :boom} = Deployments.list_targets(Strategy)
    end
  end

  describe "height reads" do
    @height 12_345
    @metadata %{"x-cosmos-block-height" => "12345"}

    setup do
      MockNode.expect(fn %QueryContractInfosRequest{} ->
        {:ok,
         %{
           infos: [
             %ContractInfo{address: "thor1fin", contract: "rujira-fin", version: "1"}
           ]
         }}
      end)

      :ok
    end

    test "list_all_targets/1 carries the block-height metadata" do
      assert {:ok, [%{address: "thor1fin", module: Pair}]} =
               Deployments.list_all_targets(height: @height)

      assert_received {:mock_node, %QueryContractInfosRequest{}, opts}
      assert Keyword.get(opts, :metadata) == @metadata
    end

    test "the second read at a height is served from the cache" do
      assert {:ok, _} = Deployments.list_all_targets(height: @height)
      assert {:ok, _} = Deployments.list_all_targets(height: @height)

      assert_received {:mock_node, %QueryContractInfosRequest{}, _}
      refute_received {:mock_node, %QueryContractInfosRequest{}, _}
    end

    test "every derived lookup shares the one cached contract_infos read" do
      assert {:ok, _} = Deployments.contract_infos(height: @height)
      assert {:ok, _} = Deployments.list_all_targets(height: @height)
      assert {:ok, _} = Deployments.list_targets(Pair, height: @height)
      assert {:ok, _} = Deployments.get_target(Pair, height: @height)
      assert {:ok, _} = Deployments.from_address("thor1fin", height: @height)

      assert_received {:mock_node, %QueryContractInfosRequest{}, _}
      refute_received {:mock_node, %QueryContractInfosRequest{}, _}
    end

    test "another height reaches the node again" do
      assert {:ok, _} = Deployments.list_all_targets(height: @height)
      assert {:ok, _} = Deployments.list_all_targets(height: @height - 1)

      assert_received {:mock_node, %QueryContractInfosRequest{}, _}
      assert_received {:mock_node, %QueryContractInfosRequest{}, _}
    end

    test "list_targets/2 forwards the height through every inner lookup" do
      assert {:ok, [%{address: "thor1fin", module: Pair}]} =
               Deployments.list_targets(Pair, height: @height)

      assert_received {:mock_node, %QueryContractInfosRequest{}, opts}
      assert Keyword.get(opts, :metadata) == @metadata
    end

    test "get_target/2 forwards the height" do
      assert {:ok, %{address: "thor1fin"}} = Deployments.get_target(Pair, height: @height)

      assert_received {:mock_node, %QueryContractInfosRequest{}, opts}
      assert Keyword.get(opts, :metadata) == @metadata
    end

    test "from_address/2 forwards the height" do
      assert {:ok, %{module: Pair}} = Deployments.from_address("thor1fin", height: @height)

      assert_received {:mock_node, %QueryContractInfosRequest{}, opts}
      assert Keyword.get(opts, :metadata) == @metadata
    end

    test "a heightless read is at the head, and has none before the first advance" do
      assert {:ok, [%{address: "thor1fin"}]} = Deployments.list_all_targets()

      assert_received {:mock_node, %QueryContractInfosRequest{}, opts}

      assert Keyword.get(opts, :metadata) == %{
               "x-cosmos-block-height" => Integer.to_string(default_head())
             }

      reset_cache()
      assert {:error, :no_head} = Deployments.list_all_targets()
    end

    test "contract_infos/1 forwards the height" do
      assert {:ok, [%ContractInfo{address: "thor1fin"}]} =
               Deployments.contract_infos(height: @height)

      assert_received {:mock_node, %QueryContractInfosRequest{}, opts}
      assert Keyword.get(opts, :metadata) == @metadata
    end
  end
end
