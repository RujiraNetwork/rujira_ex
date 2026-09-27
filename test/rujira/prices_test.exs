defmodule Rujira.PricesTest do
  @moduledoc """
  A price lookup is fallible, so it answers `{:ok, _}` or `{:error, _}` and never
  a placeholder. The oracle → FIN fallback is reached for exactly one reason —
  the oracle holds no price for the asset — so a transport failure or an
  unservable height comes back as itself rather than as a FIN price.

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

  # `queryOraclePrice`'s answer for a symbol it holds no oracle price for.
  @no_oracle_price %GRPC.RPCError{
    status: 2,
    message: "fail to get price for symbol 'ATOM': Price not found: ATOM"
  }

  # The same answer via the ABCI query path: `gRPCErrorToSDKError`
  # (`baseapp/abci.go:1168`) reclassifies the plain error as `ErrInvalidRequest`
  # and appends ": invalid request".
  @no_oracle_price_abci %GRPC.RPCError{
    status: 3,
    message: "fail to get price for symbol 'RUJI': Price not found: RUJI: invalid request"
  }

  @unavailable %GRPC.RPCError{status: 14, message: "connection refused"}

  defmodule LegacyPrices do
    @moduledoc "A prices implementation that predates the `opts` arities."

    @spec get(String.t()) :: {:ok, Decimal.t()}
    def get(_ticker), do: {:ok, Decimal.new("3")}

    @spec value_usd(String.t(), integer(), integer()) :: {:ok, integer()}
    def value_usd(_ticker, amount, _decimals), do: {:ok, amount * 3}
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

  describe "Rujira.Prices.Default" do
    setup do
      Application.put_env(:rujira_ex, :prices, Rujira.Prices.Default)
      :ok
    end

    test "the oracle price is the price" do
      MockNode.expect(fn %QueryOraclePriceRequest{symbol: "ATOM"} ->
        {:ok, %{price: %{price: "1.5"}}}
      end)

      assert {:ok, price} = Prices.get("ATOM")
      assert Decimal.equal?(price, Decimal.new("1.5"))
    end

    test "bRUNE is priced as RUNE" do
      MockNode.expect(fn %QueryOraclePriceRequest{symbol: "RUNE"} ->
        {:ok, %{price: %{price: "4.25"}}}
      end)

      assert {:ok, price} = Prices.get("bRUNE")
      assert Decimal.equal?(price, Decimal.new("4.25"))
      assert_received {:mock_node, %QueryOraclePriceRequest{symbol: "RUNE"}, _opts}
    end

    test "a symbol the oracle has no price for falls back to FIN" do
      MockNode.expect(fn
        %QueryOraclePriceRequest{symbol: "ATOM"} -> {:error, @no_oracle_price}
        %QueryOraclePriceRequest{symbol: "USDC"} -> {:ok, %{price: %{price: "2.0"}}}
        %QueryContractInfosRequest{} -> {:ok, %{infos: [fin_info()]}}
        %{"config" => _} -> MockNode.ok(pair_config())
        %{"book" => _} -> MockNode.ok(book())
      end)

      # The book's mid-price (1.5) valued in the quote asset's USD price (2.0).
      assert {:ok, price} = Prices.get("ATOM")
      assert Decimal.equal?(price, Decimal.new("3.00"))
    end

    test "an empty price string is no oracle price either, and falls back to FIN" do
      MockNode.expect(fn
        %QueryOraclePriceRequest{symbol: "ATOM"} -> {:ok, %{price: %{price: ""}}}
        %QueryOraclePriceRequest{symbol: "USDC"} -> {:ok, %{price: %{price: "2.0"}}}
        %QueryContractInfosRequest{} -> {:ok, %{infos: [fin_info()]}}
        %{"config" => _} -> MockNode.ok(pair_config())
        %{"book" => _} -> MockNode.ok(book())
      end)

      assert {:ok, price} = Prices.get("ATOM")
      assert Decimal.equal?(price, Decimal.new("3.00"))
    end

    test "a reply carrying no price message at all is no oracle price" do
      MockNode.expect(fn
        %QueryOraclePriceRequest{} -> {:ok, %{price: nil}}
        %QueryContractInfosRequest{} -> {:ok, %{infos: []}}
      end)

      assert {:error, :no_price} = Prices.get("ATOM")
      assert_received {:mock_node, %QueryContractInfosRequest{}, _opts}
    end

    test "a transport error is returned as itself and never reaches FIN" do
      MockNode.expect(fn %QueryOraclePriceRequest{} -> {:error, @unavailable} end)

      assert {:error, @unavailable} = Prices.get("ATOM")
      refute_received {:mock_node, %QueryContractInfosRequest{}, _opts}
    end

    test "a price the chain renders unparseably is an error, not a FIN price" do
      MockNode.expect(fn %QueryOraclePriceRequest{} -> {:ok, %{price: %{price: "abc"}}} end)

      assert {:error, :invalid_decimal} = Prices.get("ATOM")
      refute_received {:mock_node, %QueryContractInfosRequest{}, _opts}
    end

    test "no oracle price and no FIN market is :no_price" do
      MockNode.expect(fn
        %QueryOraclePriceRequest{} -> {:error, @no_oracle_price}
        %QueryContractInfosRequest{} -> {:ok, %{infos: []}}
      end)

      assert {:error, :no_price} = Prices.get("ATOM")
    end

    test "the recorded ABCI-path not-found reply also falls back to FIN" do
      MockNode.expect(fn
        %QueryOraclePriceRequest{symbol: "RUJI"} -> {:error, @no_oracle_price_abci}
        %QueryContractInfosRequest{} -> {:ok, %{infos: []}}
      end)

      assert {:error, :no_price} = Prices.get("RUJI")
    end

    test "a not-found message for a different ticker is returned as itself" do
      wrong_ticker = %GRPC.RPCError{
        status: 2,
        message: "fail to get price for symbol 'BTC': Price not found: BTC"
      }

      MockNode.expect(fn %QueryOraclePriceRequest{symbol: "ATOM"} -> {:error, wrong_ticker} end)

      assert {:error, ^wrong_ticker} = Prices.get("ATOM")
      refute_received {:mock_node, %QueryContractInfosRequest{}, _opts}
    end

    test "a not-found message for a ticker sharing this one's prefix is returned as itself" do
      prefix_ticker = %GRPC.RPCError{
        status: 2,
        message: "fail to get price for symbol 'ATOMX': Price not found: ATOMX"
      }

      MockNode.expect(fn %QueryOraclePriceRequest{symbol: "ATOM"} -> {:error, prefix_ticker} end)

      assert {:error, ^prefix_ticker} = Prices.get("ATOM")
      refute_received {:mock_node, %QueryContractInfosRequest{}, _opts}
    end

    test "a status-3 error with another message is returned as itself" do
      other_abci_error = %GRPC.RPCError{status: 3, message: "invalid request: bad symbol"}

      MockNode.expect(fn %QueryOraclePriceRequest{symbol: "ATOM"} ->
        {:error, other_abci_error}
      end)

      assert {:error, ^other_abci_error} = Prices.get("ATOM")
      refute_received {:mock_node, %QueryContractInfosRequest{}, _opts}
    end

    test "a book quoting only one side has no mid-price, so no FIN price" do
      MockNode.expect(fn
        %QueryOraclePriceRequest{} -> {:error, @no_oracle_price}
        %QueryContractInfosRequest{} -> {:ok, %{infos: [fin_info()]}}
        %{"config" => _} -> MockNode.ok(pair_config())
        %{"book" => _} -> MockNode.ok(%{"base" => [level("2.0")], "quote" => []})
      end)

      assert {:error, :no_price} = Prices.get("ATOM")
    end

    # A zero mid-price has no test: `Rujira.Fin.Book.populate/1` divides the
    # spread by the centre, so a book that would centre on zero raises inside
    # `Book.new/2` before a price is ever returned. `Rujira.Prices.Default`
    # still refuses to price on a zero centre, for the day that changes.

    test "a pair quoting the asset against itself is no FIN price" do
      MockNode.expect(fn
        %QueryOraclePriceRequest{} -> {:error, @no_oracle_price}
        %QueryContractInfosRequest{} -> {:ok, %{infos: [fin_info()]}}
        %{"config" => _} -> MockNode.ok(%{pair_config() | "denoms" => ["gaia-atom", "gaia-atom"]})
        %{"book" => _} -> MockNode.ok(book())
      end)

      assert {:error, :no_price} = Prices.get("ATOM")
    end

    test "a FIN leg that cannot be read is returned as itself, not as :no_price" do
      MockNode.expect(fn
        %QueryOraclePriceRequest{} -> {:error, @no_oracle_price}
        %QueryContractInfosRequest{} -> {:error, @unavailable}
      end)

      assert {:error, @unavailable} = Prices.get("ATOM")
    end

    test "value_usd/3 values the amount at the price" do
      MockNode.expect(fn %QueryOraclePriceRequest{symbol: "ATOM"} ->
        {:ok, %{price: %{price: "2.0"}}}
      end)

      assert {:ok, 200} = Prices.value_usd("ATOM", 100)
    end

    test "value_usd/3 returns the lookup's error rather than valuing at zero" do
      MockNode.expect(fn %QueryOraclePriceRequest{} -> {:error, @unavailable} end)

      assert {:error, @unavailable} = Prices.value_usd("ATOM", 100)
    end
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
        %QueryOraclePriceRequest{symbol: "ATOM"} -> {:error, @no_oracle_price}
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
      refute_received {:mock_node, %QueryContractInfosRequest{}, _opts}
    end

    test "a reply that cannot be pinned to the height is an error, not a price" do
      Application.put_env(:rujira_ex, :node, HeaderlessNode)

      assert {:error, {:height_mismatch, @height, nil}} = Prices.get("ATOM", height: @height)
    end

    test "an unusable height is rejected before the node is touched" do
      MockNode.expect(fn _request -> {:ok, %{price: %{price: "1.5"}}} end)

      assert {:error, :invalid_height} = Prices.get("ATOM", height: 0)
    end

    test "value_usd/4 values the amount at the height's price" do
      MockNode.expect(fn %QueryOraclePriceRequest{symbol: "ATOM"} ->
        {:ok, %{price: %{price: "2.0"}}}
      end)

      assert {:ok, 200} = Prices.value_usd("ATOM", 100, 8, height: @height)
      assert [@metadata] = metadata_of_every_call()
    end

    test "value_usd/4 reports a height it could not read rather than valuing it at zero" do
      MockNode.expect(fn _request ->
        {:error, %GRPC.RPCError{status: 2, message: "failed to load state at height 500"}}
      end)

      assert {:error, {:height_unavailable, @height}} =
               Prices.value_usd("ATOM", 100, 8, height: @height)
    end
  end

  describe "Rujira.Prices.Noop" do
    setup do
      Application.put_env(:rujira_ex, :prices, Rujira.Prices.Noop)
      :ok
    end

    test "every lookup is a zero price, at any height" do
      assert {:ok, zero} = Prices.get("ATOM")
      assert Decimal.equal?(zero, Decimal.new(0))
      assert {:ok, zero} = Prices.get("ATOM", height: @height)
      assert Decimal.equal?(zero, Decimal.new(0))
    end

    test "every valuation is zero, at any height" do
      assert {:ok, 0} = Prices.value_usd("ATOM", 100)
      assert {:ok, 0} = Prices.value_usd("ATOM", 100, 8, height: @height)
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

    test "value_usd/4 with a height says so rather than valuing at zero" do
      assert {:error, :height_not_supported} = Prices.value_usd("ATOM", 100, 8, height: @height)
    end

    test "value_usd/4 without a height is the arity the implementation does export" do
      assert {:ok, 300} = Prices.value_usd("ATOM", 100, 8, [])
      assert {:ok, 300} = Prices.value_usd("ATOM", 100)
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

  defp level(price), do: %{"price" => price, "total" => "100"}

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
      "base" => [level("2.0")],
      "quote" => [level("1.0")]
    }
  end
end
