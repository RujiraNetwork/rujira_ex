defmodule Rujira.ThorchainSwap.StrategyTest do
  use ExUnit.Case, async: true

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

  describe "load/1" do
    setup do
      Memoize.invalidate(Strategy)
      on_exit(fn -> Memoize.invalidate(Strategy) end)
      :ok
    end

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
  end
end
