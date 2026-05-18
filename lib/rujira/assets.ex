defmodule Rujira.Assets do
  @moduledoc """
  Asset resolution for Rujira.

  Merges base-layer asset handling (chain/symbol/denom parsing) with
  app-layer token support (x/ruji, x/staking-*, x/bow-xyk-*, etc.).
  """

  alias Rujira.Assets.Asset
  alias Rujira.Assets.Metadata

  @delimiters [".", "-", "/", "~"]

  # --- Metadata ---

  @spec load_metadata(Asset.t()) :: {:ok, map()} | {:error, term()}
  def load_metadata(%Asset{id: "x/" <> _ = denom} = asset) do
    with {:ok, metadata} <- Metadata.load_metadata(denom) do
      {:ok, %{metadata | decimals: decimals(asset)}}
    end
  end

  def load_metadata(%Asset{ticker: ticker} = asset) do
    {:ok, %{symbol: ticker, decimals: decimals(asset)}}
  end

  # --- from_string ---

  @spec from_string(String.t()) :: Asset.t()
  def from_string(id) do
    %Asset{
      id: id,
      type: type(id),
      chain: chain(id),
      symbol: symbol(id),
      ticker: ticker(id)
    }
  end

  @spec from_id(String.t()) :: {:ok, Asset.t()}
  def from_id(id), do: {:ok, from_string(id)}

  # --- from_shortcode ---

  @spec from_shortcode(String.t()) :: Asset.t()
  def from_shortcode("RUJI"), do: from_string("THOR.RUJI")
  def from_shortcode("RUNE"), do: from_string("THOR.RUNE")
  def from_shortcode("TCY"), do: from_string("THOR.TCY")
  def from_shortcode("BNB"), do: from_string("BSC.BNB")
  def from_shortcode("ATOM"), do: from_string("GAIA.ATOM")

  def from_shortcode(str) do
    case String.split(str, ~r/[\.\-]/) do
      [symbol] -> from_string("#{symbol}.#{symbol}")
      [symbol, ticker] -> from_string("#{symbol}.#{ticker}")
    end
  end

  # --- chain/symbol/ticker ---

  @spec chain(String.t()) :: String.t()
  def chain("x/" <> _), do: "THOR"

  def chain(str) do
    [c | _] = String.split(str, @delimiters)
    c
  end

  @spec symbol(String.t()) :: String.t()
  def symbol("x/" <> id), do: String.upcase(id)

  def symbol(str) do
    [_, v] = String.split(str, @delimiters, parts: 2)
    v
  end

  @spec ticker(String.t()) :: String.t()
  def ticker("x/" <> id), do: String.upcase(id)

  def ticker(str) do
    [_, v] = String.split(str, @delimiters, parts: 2)
    [sym | _] = String.split(v, "-")
    sym
  end

  # --- decimals ---

  @spec decimals(Asset.t() | map()) :: non_neg_integer()
  def decimals(%{type: :layer_1, chain: "AVAX", ticker: "USDC"}), do: 6
  def decimals(%{type: :layer_1, chain: "AVAX", ticker: "USDT"}), do: 6
  def decimals(%{type: :layer_1, chain: "AVAX"}), do: 18
  def decimals(%{type: :layer_1, chain: "BASE", ticker: "USDC"}), do: 6
  def decimals(%{type: :layer_1, chain: "BASE"}), do: 18
  def decimals(%{type: :layer_1, chain: "BCH"}), do: 8
  def decimals(%{type: :layer_1, chain: "BTC"}), do: 8
  def decimals(%{type: :layer_1, chain: "BSC"}), do: 18
  def decimals(%{type: :layer_1, chain: "DOGE"}), do: 8
  def decimals(%{type: :layer_1, chain: "ETH", ticker: "USDC"}), do: 6
  def decimals(%{type: :layer_1, chain: "ETH", ticker: "USDT"}), do: 6
  def decimals(%{type: :layer_1, chain: "ETH", ticker: "WBTC"}), do: 8
  def decimals(%{type: :layer_1, chain: "ETH"}), do: 18
  def decimals(%{type: :layer_1, chain: "GAIA"}), do: 6
  def decimals(%{type: :layer_1, chain: "KUJI"}), do: 6
  def decimals(%{type: :layer_1, chain: "LTC"}), do: 8
  def decimals(%{type: :layer_1, chain: "NOBLE", ticker: "USDY"}), do: 18
  def decimals(%{type: :layer_1, chain: "NOBLE"}), do: 6
  def decimals(%{type: :layer_1, chain: "OSMO"}), do: 6
  def decimals(%{type: :layer_1, chain: "SOL"}), do: 9
  def decimals(%{type: :layer_1, chain: "TRON"}), do: 6
  def decimals(%{type: :layer_1, chain: "TON", ticker: "USDT"}), do: 6
  def decimals(%{type: :layer_1, chain: "TON"}), do: 9
  def decimals(%{type: :layer_1, chain: "XRP"}), do: 6
  def decimals(_), do: 8

  # --- type ---

  @spec type(String.t()) :: :native | :layer_1 | :synth | :trade | :secured
  def type(str) do
    cond do
      String.starts_with?(str, "THOR.") -> :native
      String.match?(str, ~r/^[A-Z]+\./) -> :layer_1
      String.match?(str, ~r/^[A-Z]+\//) -> :synth
      String.match?(str, ~r/^[A-Z]+~/) -> :trade
      String.match?(str, ~r/^[A-Z]+-/) -> :secured
      true -> :native
    end
  end

  # --- to_native ---

  @spec to_native(Asset.t() | map() | nil) :: {:ok, String.t() | nil} | {:error, term()}
  def to_native(%{id: "THOR.RUNE"}), do: {:ok, "rune"}
  def to_native(%{id: "THOR.RUJI"}), do: {:ok, "x/ruji"}
  def to_native(%{id: "THOR.TCY"}), do: {:ok, "tcy"}
  def to_native(%{id: "THOR." <> _ = id}), do: {:ok, String.downcase(id)}
  def to_native(%{id: "x/" <> _ = denom}), do: {:ok, denom}

  def to_native(%{type: "SECURED", chain: chain, symbol: symbol}) do
    {:ok, String.downcase(chain) <> "-" <> String.downcase(symbol)}
  end

  def to_native(%{type: :secured, chain: chain, symbol: symbol}) do
    {:ok, String.downcase(chain) <> "-" <> String.downcase(symbol)}
  end

  def to_native(%Asset{} = a) do
    with {:ok, secured} <- to_secured(a) do
      to_native(secured)
    end
  end

  def to_native(nil), do: {:ok, nil}

  # --- to_secured (used by to_native) ---

  @spec to_secured(Asset.t()) :: {:ok, Asset.t()} | {:error, :not_supported}
  def to_secured(%Asset{chain: "THOR"}), do: {:error, :not_supported}

  def to_secured(%Asset{id: id} = a) do
    {:ok, %{a | type: :secured, id: String.replace(id, ~r/[\.\-\/]/, "-", global: false)}}
  end

  # --- from_denom ---

  @spec from_denom(String.t()) :: {:ok, Asset.t()} | {:error, :invalid_denom}
  def from_denom("x/ruji") do
    {:ok, %Asset{id: "THOR.RUJI", type: :native, chain: "THOR", symbol: "RUJI", ticker: "RUJI"}}
  end

  def from_denom("x/staking-" <> id = denom) do
    with {:ok, staked} <- from_denom(id) do
      {:ok,
       %Asset{
         id: denom,
         type: :native,
         chain: "THOR",
         symbol: "s" <> staked.symbol,
         ticker: "s" <> staked.ticker
       }}
    end
  end

  # TODO: implement when Bow protocol is added to core
  # def from_denom("x/bow-xyk-" <> _id = _denom) do
  # end

  def from_denom("x/nami-index-" <> _ = denom) do
    with {:ok, metadata} <- load_metadata(%Asset{id: denom}) do
      {:ok,
       %Asset{
         id: denom,
         type: :native,
         chain: "THOR",
         symbol: metadata.symbol,
         ticker: metadata.symbol
       }}
    end
  end

  def from_denom("x/brune" = denom) do
    with {:ok, metadata} <- load_metadata(%Asset{id: denom}) do
      {:ok,
       %Asset{
         id: denom,
         type: :native,
         chain: "THOR",
         symbol: metadata.symbol,
         ticker: metadata.symbol
       }}
    end
  end

  def from_denom("x/" <> id = denom) do
    {:ok,
     %Asset{
       id: denom,
       type: :native,
       chain: "THOR",
       symbol: String.upcase(id),
       ticker: String.upcase(id)
     }}
  end

  def from_denom("rune") do
    {:ok, %Asset{id: "THOR.RUNE", type: :native, chain: "THOR", symbol: "RUNE", ticker: "RUNE"}}
  end

  def from_denom("tcy") do
    {:ok, %Asset{id: "THOR.TCY", type: :native, chain: "THOR", symbol: "TCY", ticker: "TCY"}}
  end

  def from_denom("thor." <> symbol) do
    symbol = String.upcase(symbol)

    {:ok,
     %Asset{id: "THOR.#{symbol}", type: :native, chain: "THOR", symbol: symbol, ticker: symbol}}
  end

  def from_denom(denom) do
    case denom |> String.upcase() |> String.split(@delimiters, parts: 2) do
      [chain, symbol] ->
        [ticker | _] = String.split(symbol, "-")

        {:ok,
         %Asset{
           id: String.upcase(denom),
           type: type(String.upcase(denom)),
           chain: if(chain == "BNB", do: "BSC", else: chain),
           symbol: symbol,
           ticker: ticker
         }}

      _ ->
        {:error, :invalid_denom}
    end
  end

  # --- eq_denom ---

  @spec eq_denom(Asset.t(), String.t()) :: boolean()
  def eq_denom(%Asset{} = a, denom) do
    case from_denom(denom) do
      {:ok, asset} -> a.chain == asset.chain and a.ticker == asset.ticker
      _ -> false
    end
  end

  # --- Display helpers ---

  @spec label(Asset.t() | map()) :: String.t()
  def label(%{chain: "ETH", ticker: "USDC"}), do: "USDC"

  def label(%{chain: chain, ticker: ticker}) when ticker in ["USDC", "USDT"],
    do: "#{ticker}.#{chain}"

  def label(%{chain: chain, ticker: "ETH"}) when chain != "ETH", do: "ETH.#{chain}"
  def label(%{ticker: ticker}), do: ticker
end
