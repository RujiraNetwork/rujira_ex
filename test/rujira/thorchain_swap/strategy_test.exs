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

  describe "new/1" do
    test "parses strategy config, splitting the fee tuple" do
      assert {:ok,
              %Strategy{
                id: "thor1strategy",
                address: "thor1strategy",
                max_stream_length: 10,
                spread_bps: 50,
                min_borrow_amount: 100_000_000,
                fee_address: "thor1fee",
                stream_step_ratio: stream_step_ratio,
                max_borrow_ratio: max_borrow_ratio,
                reserve_fee: reserve_fee,
                fee: fee,
                markets: :not_loaded,
                vaults: :not_loaded
              }} =
               Strategy.new(%{
                 "address" => "thor1strategy",
                 "max_stream_length" => 10,
                 "stream_step_ratio" => "0.1",
                 "spread_bps" => 50,
                 "max_borrow_ratio" => "0.8",
                 "min_borrow_amount" => "100000000",
                 "reserve_fee" => "0.02",
                 "fee" => ["0.001", "thor1fee"]
               })

      assert Decimal.equal?(stream_step_ratio, Decimal.new("0.1"))
      assert Decimal.equal?(max_borrow_ratio, Decimal.new("0.8"))
      assert Decimal.equal?(reserve_fee, Decimal.new("0.02"))
      assert Decimal.equal?(fee, Decimal.new("0.001"))
    end

    test "errors on missing fields" do
      assert {:error, :invalid_attrs} = Strategy.new(%{})
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
