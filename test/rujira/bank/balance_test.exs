defmodule Rujira.Bank.BalanceTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

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

    test "a missing balance resolves to amount 0" do
      MockNode.expect(fn %QueryBalanceRequest{address: "thor1abc", denom: "btc-btc"} ->
        {:ok, %QueryBalanceResponse{balance: nil}}
      end)

      assert {:ok, %Coin{asset: @btc, amount: 0}} = Balance.get("thor1abc", @btc)
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

    test "skips an unresolvable denom and keeps the rest" do
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

      log =
        capture_log(fn ->
          assert {:ok,
                  [
                    %Coin{asset: @rune, amount: 1000},
                    %Coin{asset: @ruji, amount: 500}
                  ]} = Balance.list("thor1abc")
        end)

      assert log =~ ~s(skipping unrecognised denom "ibc/ABC")
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
end
