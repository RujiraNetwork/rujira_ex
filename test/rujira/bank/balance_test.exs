defmodule Rujira.Bank.BalanceTest do
  use Rujira.Test.CacheCase, async: false

  alias Cosmos.Bank.V1beta1.QueryAllBalancesRequest
  alias Cosmos.Bank.V1beta1.QueryAllBalancesResponse
  alias Cosmos.Bank.V1beta1.QueryBalanceRequest
  alias Cosmos.Bank.V1beta1.QueryBalanceResponse
  alias Cosmos.Bank.V1beta1.QuerySpendableBalancesRequest
  alias Cosmos.Bank.V1beta1.QuerySpendableBalancesResponse
  alias Cosmos.Base.Query.V1beta1.PageResponse
  alias Cosmos.Base.V1beta1.Coin, as: ChainCoin
  alias Rujira.Assets
  alias Rujira.Assets.Asset
  alias Rujira.Bank.Balance
  alias Rujira.Coin
  alias Rujira.Test.MockNode

  @rune elem(Assets.from_denom("rune"), 1)
  @ruji elem(Assets.from_denom("x/ruji"), 1)
  @btc elem(Assets.from_denom("btc-btc"), 1)
  @non_native %Asset{id: "RUNE", type: :native, chain: "THOR", symbol: "RUNE", ticker: "RUNE"}

  describe "get/2" do
    test "returns the amount for an existing balance" do
      MockNode.expect(fn %QueryBalanceRequest{address: "thor1abc", denom: "rune"} ->
        {:ok, %QueryBalanceResponse{balance: %ChainCoin{denom: "rune", amount: "1000"}}}
      end)

      assert {:ok, %Coin{asset: @rune, amount: 1000}} = Balance.get("thor1abc", @rune)
    end

    test "a real zero balance resolves to amount 0" do
      MockNode.expect(fn %QueryBalanceRequest{address: "thor1abc", denom: "btc-btc"} ->
        {:ok, %QueryBalanceResponse{balance: %ChainCoin{denom: "btc-btc", amount: "0"}}}
      end)

      assert {:ok, %Coin{asset: @btc, amount: 0}} = Balance.get("thor1abc", @btc)
    end

    test "a malformed response with no balance field errors" do
      MockNode.expect(fn %QueryBalanceRequest{address: "thor1abc", denom: "btc-btc"} ->
        {:ok, %QueryBalanceResponse{balance: nil}}
      end)

      assert {:error, :invalid_response} = Balance.get("thor1abc", @btc)
    end

    test "errors when the asset has no native denom" do
      assert {:error, :no_native_denom} = Balance.get("thor1abc", @non_native)
    end
  end

  describe "list/1" do
    test "paginates through all balances" do
      MockNode.expect(fn
        %QueryAllBalancesRequest{address: "thor1abc", pagination: nil} ->
          {:ok,
           %QueryAllBalancesResponse{
             balances: [%ChainCoin{denom: "rune", amount: "1000"}],
             pagination: %PageResponse{next_key: "page2"}
           }}

        %QueryAllBalancesRequest{address: "thor1abc", pagination: %{key: "page2"}} ->
          {:ok,
           %QueryAllBalancesResponse{
             balances: [%ChainCoin{denom: "x/ruji", amount: "500"}],
             pagination: %PageResponse{next_key: ""}
           }}
      end)

      assert {:ok,
              [
                %Coin{asset: @rune, amount: 1000},
                %Coin{asset: @ruji, amount: 500}
              ]} = Balance.list("thor1abc")
    end

    test "an unresolvable denom fails the whole call" do
      MockNode.expect(fn %QueryAllBalancesRequest{} ->
        {:ok,
         %QueryAllBalancesResponse{
           balances: [
             %ChainCoin{denom: "rune", amount: "1000"},
             %ChainCoin{denom: "ibc/ABC", amount: "7"},
             %ChainCoin{denom: "x/ruji", amount: "500"}
           ],
           pagination: %PageResponse{next_key: ""}
         }}
      end)

      assert {:error, :invalid_denom} = Balance.list("thor1abc")
    end

    test "still errors the whole call on an unparseable amount" do
      MockNode.expect(fn %QueryAllBalancesRequest{} ->
        {:ok,
         %QueryAllBalancesResponse{
           balances: [%ChainCoin{denom: "rune", amount: "not a number"}],
           pagination: %PageResponse{next_key: ""}
         }}
      end)

      assert {:error, :invalid_amount} = Balance.list("thor1abc")
    end
  end

  describe "list_spendable/1" do
    test "returns spendable balances" do
      MockNode.expect(fn %QuerySpendableBalancesRequest{address: "thor1abc"} ->
        {:ok,
         %QuerySpendableBalancesResponse{
           balances: [%ChainCoin{denom: "btc-btc", amount: "750"}],
           pagination: %PageResponse{next_key: ""}
         }}
      end)

      assert {:ok, [%Coin{asset: @btc, amount: 750}]} = Balance.list_spendable("thor1abc")
    end
  end

  describe "height reads" do
    @height 12_345
    @metadata %{"x-cosmos-block-height" => "12345"}

    test "get/3 carries the block-height metadata" do
      MockNode.expect(fn %QueryBalanceRequest{} ->
        {:ok, %QueryBalanceResponse{balance: %ChainCoin{denom: "rune", amount: "1000"}}}
      end)

      assert {:ok, %Coin{amount: 1000}} = Balance.get("thor1abc", @rune, height: @height)

      assert_received {:mock_node, %QueryBalanceRequest{}, opts}
      assert Keyword.get(opts, :metadata) == @metadata
    end

    test "a second read at the same height is served from the cache" do
      MockNode.expect(fn %QueryBalanceRequest{} ->
        {:ok, %QueryBalanceResponse{balance: %ChainCoin{denom: "rune", amount: "1000"}}}
      end)

      assert {:ok, _} = Balance.get("thor1abc", @rune, height: @height)
      assert {:ok, _} = Balance.get("thor1abc", @rune, height: @height)

      assert_received {:mock_node, %QueryBalanceRequest{}, _}
      refute_received {:mock_node, %QueryBalanceRequest{}, _}
    end

    test "list/2 forwards the height to every page" do
      MockNode.expect(fn
        %QueryAllBalancesRequest{pagination: nil} ->
          {:ok,
           %QueryAllBalancesResponse{
             balances: [%ChainCoin{denom: "rune", amount: "1000"}],
             pagination: %PageResponse{next_key: "page2"}
           }}

        %QueryAllBalancesRequest{pagination: %{key: "page2"}} ->
          {:ok,
           %QueryAllBalancesResponse{
             balances: [%ChainCoin{denom: "x/ruji", amount: "500"}],
             pagination: %PageResponse{next_key: ""}
           }}
      end)

      assert {:ok, [%Coin{amount: 1000}, %Coin{amount: 500}]} =
               Balance.list("thor1abc", height: @height)

      assert_received {:mock_node, %QueryAllBalancesRequest{pagination: nil}, first}
      assert Keyword.get(first, :metadata) == @metadata

      assert_received {:mock_node, %QueryAllBalancesRequest{pagination: %{key: "page2"}}, second}
      assert Keyword.get(second, :metadata) == @metadata
    end

    test "list_spendable/2 forwards the height" do
      MockNode.expect(fn %QuerySpendableBalancesRequest{} ->
        {:ok,
         %QuerySpendableBalancesResponse{
           balances: [%ChainCoin{denom: "btc-btc", amount: "750"}],
           pagination: %PageResponse{next_key: ""}
         }}
      end)

      assert {:ok, [%Coin{amount: 750}]} = Balance.list_spendable("thor1abc", height: @height)

      assert_received {:mock_node, %QuerySpendableBalancesRequest{}, opts}
      assert Keyword.get(opts, :metadata) == @metadata
    end

    test "the Rujira.Bank facade exposes the opts arity" do
      MockNode.expect(fn %QueryAllBalancesRequest{} ->
        {:ok,
         %QueryAllBalancesResponse{
           balances: [%ChainCoin{denom: "rune", amount: "1000"}],
           pagination: %PageResponse{next_key: ""}
         }}
      end)

      assert {:ok, [%Coin{amount: 1000}]} = Rujira.Bank.balances("thor1abc", height: @height)

      assert_received {:mock_node, %QueryAllBalancesRequest{}, opts}
      assert Keyword.get(opts, :metadata) == @metadata
    end
  end
end
