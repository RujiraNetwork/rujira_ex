defmodule Rujira.Bank.SupplyTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias Cosmos.Bank.V1beta1.QuerySupplyOfRequest
  alias Cosmos.Bank.V1beta1.QuerySupplyOfResponse
  alias Cosmos.Bank.V1beta1.QueryTotalSupplyRequest
  alias Cosmos.Bank.V1beta1.QueryTotalSupplyResponse
  alias Cosmos.Base.Query.V1beta1.PageResponse
  alias Cosmos.Base.V1beta1.Coin, as: ChainCoin
  alias Rujira.Assets
  alias Rujira.Assets.Asset
  alias Rujira.Bank.Supply
  alias Rujira.Coin
  alias Rujira.Test.MockNode

  @rune elem(Assets.from_denom("rune"), 1)
  @ruji elem(Assets.from_denom("x/ruji"), 1)
  @btc elem(Assets.from_denom("btc-btc"), 1)
  @non_native %Asset{id: "RUNE", type: :native, chain: "THOR", symbol: "RUNE", ticker: "RUNE"}

  describe "get/1" do
    test "returns the total supply of an asset" do
      MockNode.expect(fn %QuerySupplyOfRequest{denom: "rune"} ->
        {:ok, %QuerySupplyOfResponse{amount: %ChainCoin{denom: "rune", amount: "1000"}}}
      end)

      assert {:ok, %Coin{asset: @rune, amount: 1000}} = Supply.get(@rune)
    end

    test "errors when the asset has no native denom" do
      assert {:error, :no_native_denom} = Supply.get(@non_native)
    end
  end

  describe "list/0" do
    test "paginates through the total supply" do
      MockNode.expect(fn
        %QueryTotalSupplyRequest{pagination: nil} ->
          {:ok,
           %QueryTotalSupplyResponse{
             supply: [%ChainCoin{denom: "rune", amount: "1000"}],
             pagination: %PageResponse{next_key: "page2"}
           }}

        %QueryTotalSupplyRequest{pagination: %{key: "page2"}} ->
          {:ok,
           %QueryTotalSupplyResponse{
             supply: [%ChainCoin{denom: "x/ruji", amount: "500"}],
             pagination: %PageResponse{next_key: ""}
           }}
      end)

      assert {:ok,
              [
                %Coin{asset: @rune, amount: 1000},
                %Coin{asset: @ruji, amount: 500}
              ]} = Supply.list()
    end

    test "skips an unresolvable denom and keeps the rest" do
      MockNode.expect(fn %QueryTotalSupplyRequest{} ->
        {:ok,
         %QueryTotalSupplyResponse{
           supply: [
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
                  ]} = Supply.list()
        end)

      assert log =~ ~s(skipping unrecognised denom "ibc/ABC")
    end

    test "still errors the whole call on an unparseable amount" do
      MockNode.expect(fn %QueryTotalSupplyRequest{} ->
        {:ok,
         %QueryTotalSupplyResponse{
           supply: [%ChainCoin{denom: "rune", amount: "not a number"}],
           pagination: %PageResponse{next_key: ""}
         }}
      end)

      assert {:error, :invalid_amount} = Supply.list()
    end

    test "resolves a secured asset denom" do
      MockNode.expect(fn %QueryTotalSupplyRequest{} ->
        {:ok,
         %QueryTotalSupplyResponse{
           supply: [%ChainCoin{denom: "btc-btc", amount: "42"}],
           pagination: %PageResponse{next_key: ""}
         }}
      end)

      assert {:ok, [%Coin{asset: @btc, amount: 42}]} = Supply.list()
    end
  end
end
