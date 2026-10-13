defmodule Rujira.ThorchainSwap.StrategyTest do
  @moduledoc """
  `query_markets/2` and `query_vaults/2` read through `Rujira.Cache`, whose
  stores and head are global, so this case runs sync and starts from an empty
  cache.
  """
  use Rujira.Test.CacheCase, async: false

  alias Rujira.ThorchainSwap.Strategy
  alias Rujira.ThorchainSwap.Strategy.Vault
  alias Rujira.Test.MockNode
  alias Cosmwasm.Wasm.V1.QuerySmartContractStateRequest
  alias Thorchain.Types.ContractInfo
  alias Thorchain.Types.QueryContractInfosRequest

  defp info(address),
    do: %ContractInfo{address: address, contract: "rujira-thorchain-swap", version: "1"}

  # One config per shape the contract has served, keyed by the first
  # contract version serving it. v0.0.1 and v1.2.0 are mainnet replies at
  # height 28222789; the others follow the upstream schema at that version.
  defp config(:v0_0_1) do
    %{
      "address" => "thor1zmud8xx7nc86dg296dxru04y2uy85fd4yss9jp4t8s6hdrquma5q2y4a4d",
      "min_slip_bps" => 10,
      "max_stream_length" => 1,
      "stream_step_ratio" => "0.99",
      "max_borrow_ratio" => "0.1",
      "reserve_fee" => "0.002"
    }
  end

  defp config(:v0_0_6), do: Map.delete(config(:v0_0_1), "min_slip_bps")

  defp config(:v1_0_0),
    do: Map.put(config(:v0_0_6), "fee", ["0.00025", "thor1fee"])

  defp config(:v1_1_0),
    do: Map.put(config(:v1_0_0), "min_borrow_amount", "100")

  defp config(:v1_2_0) do
    %{
      "address" => "thor1n5a08r0zvmqca39ka2tgwlkjy9ugalutk7fjpzptfppqcccnat2ska5t4g",
      "max_stream_length" => 1,
      "stream_step_ratio" => "0.99",
      "spread_bps" => 1,
      "max_borrow_ratio" => "0.3",
      "min_borrow_amount" => "100",
      "reserve_fee" => "0.0003",
      "fee" => ["0.00025", "thor1gm8q2gr25nzzsxzdp2mpja4hyvyhjlr4s6krcsgv2y953uu0js3qhwpus7"]
    }
  end

  describe "new/1" do
    test "parses a v1.2.0 config, splitting the fee tuple" do
      assert {:ok,
              %Strategy{
                id: "thor1n5a08r0zvmqca39ka2tgwlkjy9ugalutk7fjpzptfppqcccnat2ska5t4g",
                address: "thor1n5a08r0zvmqca39ka2tgwlkjy9ugalutk7fjpzptfppqcccnat2ska5t4g",
                max_stream_length: 1,
                min_slip_bps: nil,
                spread_bps: 1,
                min_borrow_amount: 100,
                fee_address: "thor1gm8q2gr25nzzsxzdp2mpja4hyvyhjlr4s6krcsgv2y953uu0js3qhwpus7",
                stream_step_ratio: stream_step_ratio,
                max_borrow_ratio: max_borrow_ratio,
                reserve_fee: reserve_fee,
                fee: fee,
                markets: :not_loaded,
                vaults: :not_loaded
              }} = Strategy.new(config(:v1_2_0))

      assert Decimal.equal?(stream_step_ratio, Decimal.new("0.99"))
      assert Decimal.equal?(max_borrow_ratio, Decimal.new("0.3"))
      assert Decimal.equal?(reserve_fee, Decimal.new("0.0003"))
      assert Decimal.equal?(fee, Decimal.new("0.00025"))
    end

    test "parses a v1.1.0 config, which has no spread_bps" do
      assert {:ok,
              %Strategy{
                min_slip_bps: nil,
                spread_bps: nil,
                min_borrow_amount: 100,
                fee_address: "thor1fee",
                fee: fee
              }} = Strategy.new(config(:v1_1_0))

      assert Decimal.equal?(fee, Decimal.new("0.00025"))
    end

    test "parses a v1.0.0 config, which has no min_borrow_amount" do
      assert {:ok,
              %Strategy{
                min_slip_bps: nil,
                spread_bps: nil,
                min_borrow_amount: nil,
                fee_address: "thor1fee",
                fee: fee
              }} = Strategy.new(config(:v1_0_0))

      assert Decimal.equal?(fee, Decimal.new("0.00025"))
    end

    test "parses a v0.0.6 config, which has no fee" do
      assert {:ok,
              %Strategy{
                min_slip_bps: nil,
                spread_bps: nil,
                min_borrow_amount: nil,
                fee: nil,
                fee_address: nil
              }} = Strategy.new(config(:v0_0_6))
    end

    test "parses a v0.0.1 config, keeping min_slip_bps" do
      assert {:ok,
              %Strategy{
                address: "thor1zmud8xx7nc86dg296dxru04y2uy85fd4yss9jp4t8s6hdrquma5q2y4a4d",
                max_stream_length: 1,
                min_slip_bps: 10,
                spread_bps: nil,
                min_borrow_amount: nil,
                fee: nil,
                fee_address: nil,
                stream_step_ratio: stream_step_ratio,
                max_borrow_ratio: max_borrow_ratio,
                reserve_fee: reserve_fee
              }} = Strategy.new(config(:v0_0_1))

      assert Decimal.equal?(stream_step_ratio, Decimal.new("0.99"))
      assert Decimal.equal?(max_borrow_ratio, Decimal.new("0.1"))
      assert Decimal.equal?(reserve_fee, Decimal.new("0.002"))
    end

    test "errors on missing fields" do
      assert {:error, :invalid_attrs} = Strategy.new(%{})
    end

    test "errors when a field every shape carries is missing" do
      for version <- [:v0_0_1, :v0_0_6, :v1_0_0, :v1_1_0, :v1_2_0] do
        assert {:error, :invalid_attrs} =
                 version |> config() |> Map.delete("reserve_fee") |> Strategy.new()
      end
    end

    test "a malformed newer field is not read as an older shape" do
      assert {:error, :invalid_attrs} =
               config(:v1_2_0) |> Map.put("fee", "0.00025") |> Strategy.new()

      assert {:error, :invalid_attrs} =
               config(:v1_1_0) |> Map.put("fee", "0.00025") |> Strategy.new()

      assert {:error, :invalid_attrs} =
               config(:v1_2_0) |> Map.delete("min_borrow_amount") |> Strategy.new()
    end

    test "min_slip_bps alongside a later field matches no shape" do
      assert {:error, :invalid_attrs} =
               config(:v1_0_0) |> Map.put("min_slip_bps", 10) |> Strategy.new()
    end
  end

  describe "from_id/2" do
    test "round-trips on the strategy's id" do
      config = %{
        "address" => "thor1strategy",
        "max_stream_length" => 10,
        "stream_step_ratio" => "0.1",
        "spread_bps" => 50,
        "max_borrow_ratio" => "0.8",
        "min_borrow_amount" => "100000000",
        "reserve_fee" => "0.02",
        "fee" => ["0.001", "thor1fee"]
      }

      MockNode.expect(fn %{"config" => %{}} -> MockNode.ok(config) end)
      assert {:ok, %Strategy{id: "thor1strategy"} = strategy} = Strategy.get("thor1strategy")

      MockNode.expect(fn %{"config" => %{}} -> MockNode.ok(config) end)
      assert {:ok, ^strategy} = Strategy.from_id(strategy.id)
    end

    test "a well-formed id with no contract behind it is not_found" do
      MockNode.expect(fn %{"config" => %{}} ->
        {:error, %GRPC.RPCError{status: 2, message: "codespace wasm code 22: no such contract"}}
      end)

      assert {:error, :not_found} = Strategy.from_id("thor1missing")
    end
  end

  describe "list/1" do
    test "the head moving mid fan-out does not split the list across heights" do
      parent = self()
      pinned = default_head()

      MockNode.expect(fn
        %QueryContractInfosRequest{} ->
          {:ok, %{infos: [info("thor1strategya"), info("thor1strategyb")]}}

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
          MockNode.ok(config(:v1_2_0))
      end)

      assert {:ok, [_, _]} = Strategy.list(fan_out: [max_concurrency: 1])

      expected = Integer.to_string(pinned)
      assert_received {:leg_height, ^expected}
      assert_received {:leg_height, ^expected}
    end
  end

  describe "list/1 across config shapes" do
    test "lists strategies serving the old and the current shape together" do
      configs = %{
        "thor1old" => config(:v0_0_1),
        "thor1current" => config(:v1_2_0)
      }

      MockNode.expect(fn
        %QueryContractInfosRequest{} ->
          {:ok, %{infos: [info("thor1old"), info("thor1current")]}}

        %{"config" => _} ->
          # The leg's own mailbox holds the request it is answering.
          receive do
            {:mock_node, %QuerySmartContractStateRequest{address: address}, _opts} ->
              MockNode.ok(Map.fetch!(configs, address))
          end
      end)

      assert {:ok, [%Strategy{min_slip_bps: 10}, %Strategy{spread_bps: 1}]} = Strategy.list()
    end
  end

  describe "load/1" do
    test "resolves secured denoms in vaults" do
      MockNode.expect(fn
        %{"markets" => %{}} ->
          MockNode.ok(%{"markets" => ["thor1market"]})

        %{"vaults" => %{}} ->
          MockNode.ok(%{"vaults" => [%{"denom" => "btc-btc", "vault" => "thor1vault"}]})
      end)

      strategy = %Strategy{address: "thor1strategy"}

      assert {:ok, %Strategy{markets: ["thor1market"], vaults: [%Vault{} = vault]}} =
               Strategy.load(strategy)

      assert vault.asset.id == "BTC-BTC"
      assert vault.address == "thor1vault"
    end

    test "resolves native denoms in vaults" do
      MockNode.expect(fn
        %{"markets" => %{}} ->
          MockNode.ok(%{"markets" => []})

        %{"vaults" => %{}} ->
          MockNode.ok(%{"vaults" => [%{"denom" => "rune", "vault" => "thor1vault"}]})
      end)

      strategy = %Strategy{address: "thor1strategy"}

      assert {:ok, %Strategy{markets: [], vaults: [%Vault{} = vault]}} =
               Strategy.load(strategy)

      assert vault.asset.id == "THOR.RUNE"
      assert vault.address == "thor1vault"
    end

    test "fails on unresolvable denoms in vaults" do
      MockNode.expect(fn
        %{"markets" => %{}} ->
          MockNode.ok(%{"markets" => []})

        %{"vaults" => %{}} ->
          MockNode.ok(%{"vaults" => [%{"denom" => "INVALID", "vault" => "thor1vault"}]})
      end)

      strategy = %Strategy{address: "thor1strategy"}

      assert {:error, :invalid_denom} = Strategy.load(strategy)
    end

    test "propagates a query failure" do
      MockNode.expect(fn _ -> {:error, %GRPC.RPCError{status: 2, message: "boom"}} end)

      assert {:error, %GRPC.RPCError{}} = Strategy.load(%Strategy{address: "thor1strategy"})
    end

    test "a reply missing 'markets' is invalid_response, not a raw success" do
      MockNode.expect(fn
        %{"markets" => %{}} -> MockNode.ok(%{})
        %{"vaults" => %{}} -> MockNode.ok(%{"vaults" => []})
      end)

      assert {:error, :invalid_response} = Strategy.load(%Strategy{address: "thor1strategy"})
    end

    test "a reply missing 'vaults' is invalid_response, not a raw success" do
      MockNode.expect(fn
        %{"markets" => %{}} -> MockNode.ok(%{"markets" => []})
        %{"vaults" => %{}} -> MockNode.ok(%{})
      end)

      assert {:error, :invalid_response} = Strategy.load(%Strategy{address: "thor1strategy"})
    end
  end

  describe "query_markets/2 and query_vaults/2" do
    test "a second read at the same height is served from the cache" do
      MockNode.expect(fn
        %{"markets" => %{}} -> MockNode.ok(%{"markets" => []})
        %{"vaults" => %{}} -> MockNode.ok(%{"vaults" => []})
      end)

      assert {:ok, []} = Strategy.query_markets("thor1strategy", height: default_head())
      assert {:ok, []} = Strategy.query_markets("thor1strategy", height: default_head())
      assert {:ok, []} = Strategy.query_vaults("thor1strategy", height: default_head())
      assert {:ok, []} = Strategy.query_vaults("thor1strategy", height: default_head())

      assert_received {:mock_node, _, _}
      assert_received {:mock_node, _, _}
      refute_received {:mock_node, _, _}
    end
  end
end
