defmodule Rujira.Bank.HolderTest do
  use ExUnit.Case, async: true

  alias Cosmos.Bank.V1beta1.DenomOwner
  alias Cosmos.Bank.V1beta1.QueryDenomOwnersRequest
  alias Cosmos.Bank.V1beta1.QueryDenomOwnersResponse
  alias Cosmos.Base.Query.V1beta1.PageResponse
  alias Cosmos.Base.V1beta1.Coin, as: ChainCoin
  alias Rujira.Assets
  alias Rujira.Assets.Asset
  alias Rujira.Bank.Holder
  alias Rujira.Coin
  alias Rujira.Test.MockNode

  @rune elem(Assets.from_denom("rune"), 1)
  @non_native %Asset{id: "RUNE", type: :native, chain: "THOR", symbol: "RUNE", ticker: "RUNE"}

  describe "new/1" do
    test "parses a denom owner" do
      assert {:ok, %Holder{address: "thor1abc", balance: %Coin{asset: @rune, amount: 1000}}} =
               Holder.new(%{address: "thor1abc", balance: %{denom: "rune", amount: "1000"}})
    end

    test "errors on a malformed owner" do
      assert {:error, :invalid_attrs} = Holder.new(%{})
    end
  end

  describe "holders/2" do
    setup do
      Memoize.invalidate(Holder)
      on_exit(fn -> Memoize.invalidate(Holder) end)
      :ok
    end

    test "sorts owners by balance descending and applies the limit" do
      MockNode.expect(fn %QueryDenomOwnersRequest{denom: "rune"} ->
        {:ok,
         %QueryDenomOwnersResponse{
           denom_owners: [
             %DenomOwner{
               address: "thor1small",
               balance: %ChainCoin{denom: "rune", amount: "100"}
             },
             %DenomOwner{address: "thor1big", balance: %ChainCoin{denom: "rune", amount: "9000"}},
             %DenomOwner{address: "thor1mid", balance: %ChainCoin{denom: "rune", amount: "500"}}
           ],
           pagination: %PageResponse{next_key: ""}
         }}
      end)

      assert {:ok,
              [
                %Holder{address: "thor1big", balance: %Coin{asset: @rune, amount: 9000}},
                %Holder{address: "thor1mid", balance: %Coin{asset: @rune, amount: 500}}
              ]} = Holder.holders(@rune, 2)
    end

    test "paginates through all denom owners" do
      MockNode.expect(fn
        %QueryDenomOwnersRequest{denom: "rune", pagination: nil} ->
          {:ok,
           %QueryDenomOwnersResponse{
             denom_owners: [
               %DenomOwner{address: "thor1a", balance: %ChainCoin{denom: "rune", amount: "100"}}
             ],
             pagination: %PageResponse{next_key: "page2"}
           }}

        %QueryDenomOwnersRequest{denom: "rune", pagination: %{key: "page2"}} ->
          {:ok,
           %QueryDenomOwnersResponse{
             denom_owners: [
               %DenomOwner{address: "thor1b", balance: %ChainCoin{denom: "rune", amount: "200"}}
             ],
             pagination: %PageResponse{next_key: ""}
           }}
      end)

      assert {:ok,
              [
                %Holder{address: "thor1b", balance: %Coin{asset: @rune, amount: 200}},
                %Holder{address: "thor1a", balance: %Coin{asset: @rune, amount: 100}}
              ]} = Holder.holders(@rune)
    end

    test "a malformed owner errors" do
      MockNode.expect(fn %QueryDenomOwnersRequest{} ->
        {:ok,
         %QueryDenomOwnersResponse{
           denom_owners: [%DenomOwner{}],
           pagination: %PageResponse{next_key: ""}
         }}
      end)

      assert {:error, :invalid_attrs} = Holder.holders(@rune)
    end

    test "errors when the asset has no native denom" do
      assert {:error, :no_native_denom} = Holder.holders(@non_native)
    end
  end
end
