defmodule Rujira.DeploymentsTest do
  use ExUnit.Case, async: false

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

      Deployments.invalidate()
    end)

    :ok
  end

  describe "protocol_modules" do
    test "a consumer entry overrides a built-in default" do
      Application.put_env(:rujira_ex, :protocol_modules, %{
        "rujira-thorchain-swap" => CustomStrategy
      })

      Deployments.invalidate()

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
      Deployments.invalidate()

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

    test "a height read is never cached, so two calls reach the node twice" do
      assert {:ok, _} = Deployments.list_all_targets(height: @height)
      assert {:ok, _} = Deployments.list_all_targets(height: @height)

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

    test "contract_infos/1 forwards the height" do
      assert {:ok, [%ContractInfo{address: "thor1fin"}]} =
               Deployments.contract_infos(height: @height)

      assert_received {:mock_node, %QueryContractInfosRequest{}, opts}
      assert Keyword.get(opts, :metadata) == @metadata
    end
  end
end
