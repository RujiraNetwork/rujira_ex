defmodule Rujira.PricesTest do
  @moduledoc """
  A position read at a height has to be valued at that height, so every price
  lookup carries `opts` down to the node. An implementation that cannot serve a
  height says so - it never answers with today's price.
  """
  use ExUnit.Case, async: false

  alias Rujira.Prices
  alias Rujira.Test.MockNode
  alias Thorchain.Types.ContractInfo
  alias Thorchain.Types.QueryContractInfosRequest
  alias Thorchain.Types.QueryOraclePriceRequest

  @height 500
  @metadata %{"x-cosmos-block-height" => "500"}

  defmodule LegacyPrices do
    @moduledoc "A prices implementation that predates the `opts` arities."

    @spec get(String.t()) :: {:ok, Decimal.t()}
    def get(_ticker), do: {:ok, Decimal.new("3")}

    @spec value_usd(String.t(), integer(), integer()) :: integer()
    def value_usd(_ticker, amount, _decimals), do: amount * 3
  end

  defmodule HeaderlessNode do
    @moduledoc "A node whose replies drop the block-height header."
    @behaviour Rujira.Node

    @impl true
    def query(_fun, _request, _opts), do: {:ok, %{price: %{price: "1.5"}}}
  end

  setup do
    prices = Application.get_env(:rujira_ex, :prices)
    node = Application.get_env(:rujira_ex, :node)

    on_exit(fn ->
      Application.put_env(:rujira_ex, :prices, prices)
      Application.put_env(:rujira_ex, :node, node)
      Memoize.invalidate()
    end)

    Memoize.invalidate()
    :ok
  end

  describe "Rujira.Prices.Default at a height" do
    setup do
      Application.put_env(:rujira_ex, :prices, Rujira.Prices.Default)
      :ok
    end

    test "the oracle path forwards the height to the node" do
      MockNode.expect(fn %QueryOraclePriceRequest{symbol: "ATOM"} ->
        {:ok, %{price: %{price: "1.5"}}}
      end)

      assert {:ok, price} = Prices.get("ATOM", height: @height)
      assert Decimal.equal?(price, Decimal.new("1.5"))
      assert [@metadata] = metadata_of_every_call()
    end

    test "the FIN fallback forwards the height to every leg it reads" do
      MockNode.expect(fn
        %QueryOraclePriceRequest{symbol: "ATOM"} -> {:error, %GRPC.RPCError{status: 5}}
        %QueryOraclePriceRequest{symbol: "USDC"} -> {:ok, %{price: %{price: "2.0"}}}
        %QueryContractInfosRequest{} -> {:ok, %{infos: [fin_info()]}}
        %{"config" => _} -> MockNode.ok(pair_config())
        %{"book" => _} -> MockNode.ok(book())
      end)

      # The book's mid-price (1.5) valued in the quote asset's USD price (2.0).
      assert {:ok, price} = Prices.get("ATOM", height: @height)
      assert Decimal.equal?(price, Decimal.new("3.00"))

      calls = metadata_of_every_call()
      assert length(calls) > 1
      assert Enum.all?(calls, &(&1 == @metadata))
    end

    test "a height the node cannot serve is an error, not a fallback price" do
      MockNode.expect(fn _request ->
        {:error, %GRPC.RPCError{status: 2, message: "failed to load state at height 500"}}
      end)

      assert {:error, {:height_unavailable, @height}} = Prices.get("ATOM", height: @height)
    end

    test "a reply that cannot be pinned to the height is an error, not a price" do
      Application.put_env(:rujira_ex, :node, HeaderlessNode)

      assert {:error, {:height_mismatch, @height, nil}} = Prices.get("ATOM", height: @height)
    end

    test "an unusable height is rejected before the node is touched" do
      MockNode.expect(fn _request -> {:ok, %{price: %{price: "1.5"}}} end)

      assert {:error, :invalid_height} = Prices.get("ATOM", height: 0)
    end

    test "still falls back to FIN, and still answers :no_price, for any other error" do
      MockNode.expect(fn _request -> {:error, %GRPC.RPCError{status: 5}} end)

      assert {:error, :no_price} = Prices.get("ATOM")
      assert_received {:mock_node, %QueryContractInfosRequest{}, _opts}
    end

    test "value_usd/4 values the amount at the height's price" do
      MockNode.expect(fn %QueryOraclePriceRequest{symbol: "ATOM"} ->
        {:ok, %{price: %{price: "2.0"}}}
      end)

      assert Prices.value_usd("ATOM", 100, 8, height: @height) == 200
      assert [@metadata] = metadata_of_every_call()
    end

    test "value_usd/4 values a height it could not read at 0 rather than at today's price" do
      MockNode.expect(fn _request ->
        {:error, %GRPC.RPCError{status: 2, message: "failed to load state at height 500"}}
      end)

      assert Prices.value_usd("ATOM", 100, 8, height: @height) == 0
    end
  end

  describe "an implementation without the opts arities" do
    setup do
      Application.put_env(:rujira_ex, :prices, LegacyPrices)
      :ok
    end

    test "get/2 with a height says so rather than answering with today's price" do
      assert {:error, :height_not_supported} = Prices.get("ATOM", height: @height)
    end

    test "get/2 without a height is the arity the implementation does export" do
      assert {:ok, price} = Prices.get("ATOM", [])
      assert Decimal.equal?(price, Decimal.new("3"))
      assert {:ok, ^price} = Prices.get("ATOM")
    end

    test "value_usd/4 with a height is 0, having no error channel of its own" do
      assert Prices.value_usd("ATOM", 100, 8, height: @height) == 0
    end

    test "value_usd/4 without a height is the arity the implementation does export" do
      assert Prices.value_usd("ATOM", 100, 8, []) == 300
      assert Prices.value_usd("ATOM", 100) == 300
    end
  end

  # --- Helpers ---

  defp metadata_of_every_call(acc \\ []) do
    receive do
      {:mock_node, _request, opts} -> metadata_of_every_call([Keyword.get(opts, :metadata) | acc])
    after
      0 -> Enum.reverse(acc)
    end
  end

  # --- Fixtures ---

  defp fin_info,
    do: %ContractInfo{address: "thor1pair", contract: "rujira-fin", version: "1"}

  defp pair_config do
    %{
      "address" => "thor1pair",
      "market_makers" => [],
      "denoms" => ["gaia-atom", "eth-usdc-0xabc"],
      "oracles" => [],
      "tick" => 6,
      "fee_taker" => "0.0015",
      "fee_maker" => "0.00075",
      "fee_address" => "thor1fee"
    }
  end

  defp book do
    %{
      "base" => [%{"price" => "2.0", "total" => "100"}],
      "quote" => [%{"price" => "1.0", "total" => "100"}]
    }
  end
end
