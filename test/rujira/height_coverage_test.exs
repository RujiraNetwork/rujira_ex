defmodule Rujira.HeightCoverageTest do
  @moduledoc """
  One table per protocol facade, listing every public function that reaches the
  node. Each is called with `height:` and must carry `x-cosmos-block-height` on
  its first node call - a facade that forwards `opts` to some of its queries but
  not to the one it happens to reach first is the bug this catches.

  A function that does not carry the height in metadata - because it never
  reaches the node, or because it takes the height as an argument rather than as
  an opt - is listed in `@excluded` with why. The two lists together must name
  every public function of the facade, so a new one fails here until it is
  classified.
  """
  use ExUnit.Case, async: true

  alias Cosmos.Bank.V1beta1.QueryAllBalancesRequest
  alias Cosmos.Base.Query.V1beta1.PageRequest
  alias Rujira.Assets
  alias Rujira.Brune
  alias Rujira.Coin
  alias Rujira.Fin
  alias Rujira.Fin.Price
  alias Rujira.Ghost
  alias Rujira.Staking
  alias Rujira.Test.MockNode
  alias Rujira.Thorchain
  alias Rujira.ThorchainSwap

  @height 12_345
  @metadata %{"x-cosmos-block-height" => "12345"}

  @excluded %{
    Fin => %{
      ticker_id!:
        "reads only denom metadata, which is identity resolved at latest - see conventions",
      book_depth: "pure - sums an already-loaded book's price levels",
      order_filled_fee: "pure - the pair's maker fee over an already-read order"
    },
    Ghost => %{
      vault_account_value: "pure - values already-loaded shares at the deposit-pool ratio"
    },
    Staking => %{
      account_revenue_share: "pure - mirrors distribute() over an already-loaded pool status",
      account_liquid_size: "pure - values receipt tokens at an already-loaded pool status"
    },
    Brune => %{},
    ThorchainSwap => %{},
    Thorchain => %{
      module_address: "pure - hashes a module name into an address, no node read",
      block: "takes its height as an argument - it travels in the request, not in metadata"
    },
    Rujira.Bank => %{}
  }

  # Every node-reaching function is exercised against a node that answers
  # nothing: the assertion is on the opts that reached it, not on the reply.
  setup do
    MockNode.expect(fn _request -> {:error, :no_reply_scripted} end)
    :ok
  end

  describe "every facade forwards height: to the node" do
    test "Rujira.Fin", do: assert_forwards_height(Fin)
    test "Rujira.Ghost", do: assert_forwards_height(Ghost)
    test "Rujira.Staking", do: assert_forwards_height(Staking)
    test "Rujira.Brune", do: assert_forwards_height(Brune)
    test "Rujira.ThorchainSwap", do: assert_forwards_height(ThorchainSwap)
    test "Rujira.Thorchain", do: assert_forwards_height(Thorchain)
    test "Rujira.Bank", do: assert_forwards_height(Rujira.Bank)
  end

  describe "composite reads take every leg at the one height" do
    test "Fin.list_ranges reads fixed and dynamic ranges at the height" do
      MockNode.expect(fn %{"ranges" => _} -> MockNode.ok(%{"ranges" => []}) end)

      assert {:ok, []} = Fin.list_ranges(pair(), nil, height: @height)
      assert [_, _] = assert_all_calls_at_height()
    end

    test "Brune reads a pool's config and its state at the height" do
      MockNode.expect(fn
        %{"config" => _} -> MockNode.ok(brune_config())
        %{"state" => _} -> MockNode.ok(brune_state())
      end)

      assert {:ok, brune_pool} = Brune.get_pool("thor1brune", height: @height)
      assert {:ok, %{state: %{minted: 0}}} = Brune.load_pool(brune_pool, height: @height)
      assert [_, _] = assert_all_calls_at_height()
    end

    test "ThorchainSwap.load_strategy reads markets and vaults at the height" do
      MockNode.expect(fn
        %{"markets" => _} -> MockNode.ok(%{"markets" => []})
        %{"vaults" => _} -> MockNode.ok(%{"vaults" => []})
      end)

      assert {:ok, %{markets: [], vaults: []}} =
               ThorchainSwap.load_strategy(strategy(), height: @height)

      assert [_, _] = assert_all_calls_at_height()
    end

    test "Thorchain.liquidity_provider reads the position at the height" do
      assert {:error, _} = Thorchain.liquidity_provider("BTC.BTC", "thor1abc", height: @height)
      assert [_] = assert_all_calls_at_height()
    end

    test "Bank.balances reads every page at the height" do
      MockNode.expect(fn
        %QueryAllBalancesRequest{pagination: nil} ->
          {:ok, %{balances: [], pagination: %{next_key: "page2"}}}

        %QueryAllBalancesRequest{pagination: %PageRequest{key: "page2"}} ->
          {:ok, %{balances: [], pagination: %{next_key: ""}}}
      end)

      assert {:ok, []} = Rujira.Bank.balances("thor1acc", height: @height)
      assert [_, _] = assert_all_calls_at_height()
    end
  end

  # --- Coverage tables ---

  defp covered(Fin) do
    pair = pair()
    price = %Price.Fixed{value: Decimal.new("1")}

    [
      {:get_pair, &Fin.get_pair("thor1pair", &1)},
      {:list_pairs, &Fin.list_pairs/1},
      {:get_stable_pair, &Fin.get_stable_pair("rune", &1)},
      {:get_default_pair, &Fin.get_default_pair("rune", &1)},
      {:denom_for_ticker, &Fin.denom_for_ticker("RUNE", &1)},
      {:get_pair_from_denoms, &Fin.get_pair_from_denoms("rune", "x/ruji", &1)},
      {:pair_from_id, &Fin.pair_from_id("thor1pair", &1)},
      {:load_pair, &Fin.load_pair(pair, nil, &1)},
      {:book_from_id, &Fin.book_from_id("thor1pair", &1)},
      {:list_orders, &Fin.list_orders(pair, "thor1owner", nil, &1)},
      {:list_pair_orders, &Fin.list_pair_orders(pair, &1)},
      {:load_order, &Fin.load_order(pair, :base, price, "thor1owner", &1)},
      {:list_all_orders, &Fin.list_all_orders("thor1owner", &1)},
      {:order_from_id, &Fin.order_from_id("thor1pair/base/fixed:1/thor1owner", &1)},
      {:list_ranges, &Fin.list_ranges(pair, nil, &1)},
      {:load_range, &Fin.load_range(pair, 1, &1)},
      {:list_all_ranges, &Fin.list_all_ranges(nil, nil, &1)},
      {:range_from_id, &Fin.range_from_id("thor1pair/1", &1)},
      {:simulate, &Fin.simulate(pair, Coin.new(rune(), 100), &1)},
      {:simulation_from_id, &Fin.simulation_from_id("thor1pair:rune:100", &1)}
    ]
  end

  defp covered(Ghost) do
    vault = vault()

    [
      {:list_vaults, &Ghost.list_vaults/1},
      {:get_vault, &Ghost.get_vault("thor1vault", &1)},
      {:vault_from_id, &Ghost.vault_from_id("thor1vault", &1)},
      {:load_vault, &Ghost.load_vault(vault, &1)},
      {:vault_borrower, &Ghost.vault_borrower("thor1vault", "thor1b", &1)},
      {:vault_borrowers, &Ghost.vault_borrowers("thor1vault", &1)},
      {:vault_delegate, &Ghost.vault_delegate("thor1vault", "thor1b", "thor1d", &1)},
      {:load_vault_account, &Ghost.load_vault_account(vault, "thor1acc", &1)},
      {:vault_account_from_id, &Ghost.vault_account_from_id("thor1vault/thor1acc", &1)}
    ]
  end

  defp covered(Staking) do
    pool = pool()

    [
      {:get_pool, &Staking.get_pool("thor1staking", &1)},
      {:list_pools, &Staking.list_pools/1},
      {:load_pool, &Staking.load_pool(pool, &1)},
      {:pool_from_id, &Staking.pool_from_id("thor1staking", &1)},
      {:load_account, &Staking.load_account(pool, "thor1acc", &1)},
      {:account_from_id, &Staking.account_from_id("thor1staking/thor1acc", &1)}
    ]
  end

  defp covered(Brune) do
    [
      {:get_pool, &Brune.get_pool("thor1brune", &1)},
      {:list_pools, &Brune.list_pools/1},
      {:load_pool, &Brune.load_pool(brune_pool(), &1)},
      {:pool_from_id, &Brune.pool_from_id("thor1brune", &1)},
      {:list_events, &Brune.list_events("thor1brune", nil, 100, &1)},
      {:quote, &Brune.quote("thor1brune", rune(), ruji(), nil, &1)}
    ]
  end

  defp covered(ThorchainSwap) do
    [
      {:get_strategy, &ThorchainSwap.get_strategy("thor1strategy", &1)},
      {:list_strategies, &ThorchainSwap.list_strategies/1},
      {:load_strategy, &ThorchainSwap.load_strategy(strategy(), &1)},
      {:strategy_from_id, &ThorchainSwap.strategy_from_id("thor1strategy", &1)},
      {:quote, &ThorchainSwap.quote("thor1strategy", rune(), ruji(), nil, &1)}
    ]
  end

  defp covered(Thorchain) do
    [
      {:network, &Thorchain.network/1},
      {:pools, &Thorchain.pools/1},
      {:pool_from_id, &Thorchain.pool_from_id("BTC.BTC", &1)},
      {:liquidity_provider, &Thorchain.liquidity_provider("BTC.BTC", "thor1abc", &1)},
      {:liquidity_provider_from_id,
       &Thorchain.liquidity_provider_from_id("BTC.BTC/thor1abc", &1)},
      {:mimirs, &Thorchain.mimirs/1},
      {:mimir_from_id, &Thorchain.mimir_from_id("HALTTHORCHAIN", &1)},
      {:halted_pools, &Thorchain.halted_pools/1},
      {:inbound_addresses, &Thorchain.inbound_addresses/1},
      {:inbound_address_from_id, &Thorchain.inbound_address_from_id("BTC", &1)},
      {:outbound_fees, &Thorchain.outbound_fees/1},
      {:outbound_fee_from_id, &Thorchain.outbound_fee_from_id("BTC.BTC", &1)}
    ]
  end

  defp covered(Rujira.Bank) do
    [
      {:balance, &Rujira.Bank.balance("thor1acc", rune(), &1)},
      {:balances, &Rujira.Bank.balances("thor1acc", &1)},
      {:spendable_balances, &Rujira.Bank.spendable_balances("thor1acc", &1)},
      {:supply, &Rujira.Bank.supply(rune(), &1)},
      {:total_supply, &Rujira.Bank.total_supply/1},
      {:holders, &Rujira.Bank.holders(rune(), &1)}
    ]
  end

  # --- Assertions ---

  defp assert_forwards_height(protocol) do
    table = covered(protocol)

    for {name, call} <- table do
      flush()
      call.(height: @height)
      assert_first_call_at_height("#{inspect(protocol)}.#{name}")
    end

    assert_every_function_classified(protocol, table)
  end

  defp assert_first_call_at_height(label) do
    receive do
      {:mock_node, _request, opts} ->
        assert Keyword.get(opts, :metadata) == @metadata,
               "#{label} reached the node without the requested height"
    after
      0 -> flunk("#{label} made no node call at height: #{@height}")
    end
  end

  defp assert_all_calls_at_height do
    calls = drain()
    assert calls != [], "the composite made no node call at height: #{@height}"

    for opts <- calls do
      assert Keyword.get(opts, :metadata) == @metadata
    end

    calls
  end

  defp assert_every_function_classified(protocol, table) do
    classified =
      table
      |> Enum.map(&elem(&1, 0))
      |> MapSet.new()
      |> MapSet.union(@excluded |> Map.fetch!(protocol) |> Map.keys() |> MapSet.new())

    unclassified =
      protocol.__info__(:functions)
      |> Enum.map(&elem(&1, 0))
      |> MapSet.new()
      |> MapSet.difference(classified)

    assert MapSet.size(unclassified) == 0,
           "#{inspect(protocol)} exposes #{inspect(MapSet.to_list(unclassified))}, " <>
             "which is neither covered here nor listed as pure in @excluded"
  end

  defp drain(acc \\ []) do
    receive do
      {:mock_node, _request, opts} -> drain([opts | acc])
    after
      0 -> Enum.reverse(acc)
    end
  end

  defp flush do
    receive do
      {:mock_node, _, _} -> flush()
    after
      0 -> :ok
    end
  end

  # --- Fixtures ---

  defp rune do
    {:ok, asset} = Assets.from_denom("rune")
    asset
  end

  defp ruji do
    {:ok, asset} = Assets.from_denom("x/ruji")
    asset
  end

  defp pair do
    %Fin.Pair{
      id: "thor1pair",
      address: "thor1pair",
      market_makers: [],
      token_base: "rune",
      token_quote: "x/ruji"
    }
  end

  defp vault do
    %Ghost.Vault{
      id: "thor1vault",
      address: "thor1vault",
      denom: "rune",
      receipt_denom: "x/ghost-vault/rune"
    }
  end

  defp pool do
    {:ok, receipt_asset} = Assets.from_denom("x/staking-rune")

    %Staking.Pool{
      id: "thor1staking",
      address: "thor1staking",
      bond_asset: rune(),
      revenue_asset: rune(),
      receipt_asset: receipt_asset
    }
  end

  defp brune_pool, do: %Brune.Pool{id: "thor1brune", address: "thor1brune"}

  defp strategy, do: %ThorchainSwap.Strategy{id: "thor1strategy", address: "thor1strategy"}

  defp brune_config do
    %{
      "address" => "thor1brune",
      "fin_contract" => "thor1fin",
      "stake_contract" => "thor1stake",
      "token_id" => "brune-pool",
      "target_utilization" => "0",
      "min_node_fee" => "0",
      "range" => %{"high" => "0", "low" => "0", "skew" => "0", "step" => "0"},
      "permissionless" => false,
      "revenue_smear" => "0",
      "quarantine" => %{"height" => "0"},
      "nodes_cache_ttl" => "0",
      "max_bond" => "0",
      "max_effective_bond" => "0",
      "mint_cap" => "0"
    }
  end

  defp brune_state do
    %{
      "minted" => "0",
      "nodes" => %{"bond" => "0", "weight" => "0", "capacity" => "0", "nodes" => []},
      "revenue" => %{"pending" => "0", "fee_rate" => "0", "timestamp" => "0"}
    }
  end
end
