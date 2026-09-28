defmodule Rujira.Ghost.CreditTest do
  # The Group A reads underneath (Deployments, Contracts) are cached per
  # `Rujira.Cache`, whose stores are global, so this case runs sync and starts
  # from an empty cache.
  use Rujira.Test.CacheCase, async: false

  alias Rujira.Ghost.Credit
  alias Rujira.Ghost.Credit.CollateralRatio
  alias Rujira.Ghost.Vault.Borrower
  alias Rujira.Test.MockNode
  alias Thorchain.Types.ContractInfo
  alias Thorchain.Types.QueryContractInfosRequest

  @height 12_345

  describe "new/1" do
    test "parses the contract config, collateral ratios sorted by denom" do
      assert {:ok,
              %Credit{
                id: "thor1credit",
                address: "thor1credit",
                code_id: 12,
                collateral_ratios: [
                  %CollateralRatio{asset: btc, ratio: btc_ratio},
                  %CollateralRatio{asset: eth, ratio: eth_ratio}
                ],
                fee_address: "thor1fee",
                full_liquidation_threshold: 100,
                borrows: :not_loaded
              } = credit} = Credit.new(config())

      assert btc.id == "BTC-BTC"
      assert eth.id == "ETH-ETH"
      assert Decimal.equal?(btc_ratio, Decimal.new("0.8"))
      assert Decimal.equal?(eth_ratio, Decimal.new("0.7"))
      assert Decimal.equal?(credit.fee_liquidation, Decimal.new("0.01"))
      assert Decimal.equal?(credit.fee_liquidator, Decimal.new("0.02"))
      assert Decimal.equal?(credit.liquidation_max_slip, Decimal.new("0.3"))
      assert Decimal.equal?(credit.liquidation_threshold, Decimal.new("1"))
      assert Decimal.equal?(credit.adjustment_threshold, Decimal.new("0.9"))
    end

    test "errors on missing fields" do
      assert {:error, :invalid_attrs} = Credit.new(%{})
    end

    test "collateral ratios that are not a map are an error" do
      assert {:error, :invalid_attrs} = Credit.new(config(%{"collateral_ratios" => []}))
    end

    test "an unrecognised collateral denom is an error" do
      assert {:error, :invalid_denom} =
               Credit.new(config(%{"collateral_ratios" => %{"not a denom" => "0.8"}}))
    end

    test "an unparseable collateral ratio is an error" do
      assert {:error, :invalid_decimal} =
               Credit.new(config(%{"collateral_ratios" => %{"btc-btc" => "eight"}}))
    end

    test "an unparseable full_liquidation_threshold is an error" do
      assert {:error, :invalid_integer} =
               Credit.new(config(%{"full_liquidation_threshold" => "lots"}))
    end

    test "an unparseable threshold decimal is an error" do
      assert {:error, :invalid_decimal} =
               Credit.new(config(%{"liquidation_threshold" => "one"}))
    end
  end

  describe "get/2 and from_id/2" do
    test "resolves a credit contract by its address, which is its id" do
      MockNode.expect(fn %{"config" => _} -> MockNode.ok(config()) end)

      assert {:ok, %Credit{id: "thor1credit", address: "thor1credit"} = credit} =
               Credit.get("thor1credit", height: @height)

      assert {:ok, ^credit} = Credit.from_id(credit.id, height: @height)
    end

    test "a well-formed id with no contract behind it is not_found" do
      MockNode.expect(fn %{"config" => %{}} ->
        {:error, %GRPC.RPCError{status: 2, message: "codespace wasm code 22: no such contract"}}
      end)

      assert {:error, :not_found} = Credit.from_id("thor1creditmissing")
    end
  end

  describe "list/1" do
    test "lists every deployed credit contract" do
      MockNode.expect(fn
        %QueryContractInfosRequest{} ->
          {:ok, %{infos: [info("thor1credita"), info("thor1creditb")]}}

        %{"config" => _} ->
          MockNode.ok(config())
      end)

      assert {:ok, [%Credit{}, %Credit{}]} = Credit.list(height: @height)
    end

    test "fails as a whole when one contract read fails" do
      {:ok, agent} = Agent.start_link(fn -> 0 end)

      MockNode.expect(fn
        %QueryContractInfosRequest{} ->
          {:ok, %{infos: [info("thor1credita"), info("thor1creditb")]}}

        %{"config" => _} ->
          case Agent.get_and_update(agent, &{&1, &1 + 1}) do
            0 -> {:error, %GRPC.RPCError{status: 3, message: "boom"}}
            _ -> MockNode.ok(config())
          end
      end)

      assert {:error, %GRPC.RPCError{status: 3}} = Credit.list(height: @height)
    end
  end

  describe "load/2" do
    test "loads the contract's own vault borrower positions" do
      MockNode.expect(fn %{"borrows" => %{}} ->
        MockNode.ok(%{"borrowers" => [borrower()]})
      end)

      assert {:ok, %Credit{borrows: [%Borrower{address: "thor1credit", current: 100} = position]}} =
               Credit.load(credit(), height: @height)

      assert position.asset.id == "THOR.RUNE"
    end

    test "a malformed borrower is an error, not a dropped position" do
      MockNode.expect(fn %{"borrows" => %{}} ->
        MockNode.ok(%{"borrowers" => [Map.put(borrower(), "denom", "not a denom")]})
      end)

      assert {:error, :invalid_denom} = Credit.load(credit(), height: @height)
    end

    test "a reply without borrowers is an error, not an empty list" do
      MockNode.expect(fn %{"borrows" => %{}} -> MockNode.ok(%{}) end)

      assert {:error, :invalid_attrs} = Credit.load(credit(), height: @height)
    end

    test "hands back the query error rather than an unloaded struct" do
      MockNode.expect(fn %{"borrows" => %{}} ->
        {:error, %GRPC.RPCError{status: 3, message: "boom"}}
      end)

      assert {:error, %GRPC.RPCError{status: 3}} = Credit.load(credit(), height: @height)
    end
  end

  describe "query_borrows/2" do
    test "a second read at the same height is served from the cache" do
      MockNode.expect(fn %{"borrows" => %{}} -> MockNode.ok(%{"borrowers" => []}) end)

      assert {:ok, []} = Credit.query_borrows("thor1credit", height: @height)
      assert {:ok, []} = Credit.query_borrows("thor1credit", height: @height)

      assert_received {:mock_node, _, _}
      refute_received {:mock_node, _, _}
    end
  end

  # --- Fixtures ---

  defp credit, do: %Credit{id: "thor1credit", address: "thor1credit"}

  defp info(address),
    do: %ContractInfo{address: address, contract: "rujira-ghost-credit", version: "1.0.4"}

  defp config(overrides \\ %{}) do
    Map.merge(
      %{
        "address" => "thor1credit",
        "code_id" => 12,
        "collateral_ratios" => %{"btc-btc" => "0.8", "eth-eth" => "0.7"},
        "fee_liquidation" => "0.01",
        "fee_liquidator" => "0.02",
        "fee_address" => "thor1fee",
        "liquidation_max_slip" => "0.3",
        "liquidation_threshold" => "1",
        "adjustment_threshold" => "0.9",
        "full_liquidation_threshold" => "100"
      },
      overrides
    )
  end

  defp borrower do
    %{
      "addr" => "thor1credit",
      "denom" => "rune",
      "limit" => "500",
      "current" => "100",
      "shares" => "100.5",
      "available" => "400"
    }
  end
end
