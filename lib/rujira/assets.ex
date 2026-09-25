defmodule Rujira.Assets do
  @moduledoc """
  Asset resolution for Rujira.

  Merges base-layer asset handling (chain/symbol/denom parsing) with
  app-layer token support (x/ruji, x/staking-*, etc.).
  """

  alias Rujira.Assets.Asset
  alias Rujira.Assets.Metadata

  @delimiters [".", "-", "/", "~"]

  # A secured (`-`), synth (`/`) or trade (`~`) denom: a lowercase alphabetic
  # chain, then a lowercase alphanumeric symbol with at most one `-<id>` suffix.
  @denom_regex ~r|^([a-z]+)([-/~])([a-z0-9]+(?:-[a-z0-9]+)?)$|

  # A layer-1 (`.`), secured (`-`), synth (`/`) or trade (`~`) asset id: the same
  # shape as a denom, but case-insensitive and also accepting `.`.
  @asset_id_regex ~r|^[a-z]+[.\-/~][a-z0-9]+(?:-[a-z0-9]+)?$|i

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

  @doc """
  Builds an `Asset` from a THORChain asset id (`CHAIN.SYMBOL`, `CHAIN-SYMBOL`,
  `CHAIN/SYMBOL`, `CHAIN~SYMBOL`, or an `x/…` id).

  Chain and symbol are case-insensitive and normalised to uppercase, as THORChain
  names them, so `eth.eth` and `ETH.ETH` build the same asset. `x/…` ids are
  case-sensitive token-factory denoms and are kept as given.

  Trusts its input and raises on an id with no delimiter. Use `from_id/1` to
  validate an id from an untrusted source.
  """
  @spec from_string(String.t()) :: Asset.t()
  def from_string("x/" <> _ = id), do: build_asset(id)
  def from_string(id), do: build_asset(String.upcase(id))

  @doc """
  Validates and resolves a THORChain asset id into an `Asset` — the
  non-raising counterpart of `from_string/1`.

  An id is an alphabetic chain, one delimiter (`.` layer-1, `-` secured, `/`
  synth, `~` trade) and an alphanumeric symbol with at most one `-<id>` suffix,
  in any case; or a non-empty `x/…` token-factory id. Anything else returns
  `{:error, :invalid_asset_id}`.
  """
  @spec from_id(String.t()) :: {:ok, Asset.t()} | {:error, :invalid_asset_id}
  def from_id("x/" <> rest = id) when rest != "", do: {:ok, from_string(id)}
  def from_id(id), do: validate_id(String.match?(id, @asset_id_regex), id)

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

  @doc """
  The bank denom an asset is held under on THORChain.

  Secured assets, THOR layer-1 assets and token-factory (`x/`) denoms have one.
  A layer-1 asset on any other chain, a synth and a trade asset do not — they are
  never bank denoms, so they return `{:error, :no_native_denom}` rather than being
  silently converted to their secured form.
  """
  @spec to_native(Asset.t() | map() | nil) :: {:ok, String.t() | nil} | {:error, term()}
  def to_native(nil), do: {:ok, nil}
  def to_native(%{id: "x/" <> _ = denom}), do: {:ok, denom}

  def to_native(%{type: type, chain: chain, symbol: symbol})
      when type in [:secured, "SECURED"] do
    {:ok, String.downcase("#{chain}-#{symbol}")}
  end

  def to_native(%{id: "THOR.RUNE"}), do: {:ok, "rune"}
  def to_native(%{id: "THOR.RUJI"}), do: {:ok, "x/ruji"}
  def to_native(%{id: "THOR.TCY"}), do: {:ok, "tcy"}
  def to_native(%{id: "THOR." <> _ = id}), do: {:ok, String.downcase(id)}
  def to_native(%{id: _}), do: {:error, :no_native_denom}

  # --- to_secured ---

  @doc """
  The secured `Asset` for a layer-1 asset on another chain — the form THORChain
  credits deposits from other chains under (`BTC.BTC` becomes `BTC-BTC`).

  A secured asset is returned unchanged. Only layer-1 assets can be secured:
  THOR-chain assets, token-factory (`x/`) denoms, synths and trade assets return
  `{:error, :not_supported}`.
  """
  @spec to_secured(Asset.t()) :: {:ok, Asset.t()} | {:error, :not_supported}
  def to_secured(%Asset{chain: "THOR"}), do: {:error, :not_supported}
  def to_secured(%Asset{type: :secured} = a), do: {:ok, a}

  def to_secured(%Asset{type: :layer_1, id: id} = a) do
    {:ok, %{a | type: :secured, id: String.replace(id, ".", "-", global: false)}}
  end

  def to_secured(%Asset{}), do: {:error, :not_supported}

  # --- to_layer1 ---

  @doc """
  The layer-1 `Asset` behind a secured, synth or trade asset — the chain and
  symbol as THORChain names the underlying token (`BTC.BTC`).

  Layer-1 assets, THOR assets included, are returned unchanged. Token-factory
  (`x/`) denoms exist only on THORChain and have no layer-1 form.
  """
  @spec to_layer1(Asset.t()) :: {:ok, Asset.t()} | {:error, :not_supported}
  def to_layer1(%Asset{id: "x/" <> _}), do: {:error, :not_supported}
  def to_layer1(%Asset{type: type} = a) when type in [:layer_1, :native], do: {:ok, a}

  def to_layer1(%Asset{type: type, chain: chain, symbol: symbol} = a)
      when type in [:secured, :synth, :trade] do
    {:ok, %{a | type: :layer_1, id: "#{chain}.#{symbol}"}}
  end

  # --- pool_id ---

  @doc """
  The THORChain pool id for an asset — the id of its layer-1 form.
  """
  @spec pool_id(Asset.t()) :: {:ok, String.t()} | {:error, term()}
  def pool_id(%Asset{} = a) do
    with {:ok, %Asset{id: id}} <- to_layer1(a), do: {:ok, id}
  end

  # --- from_denom ---

  @doc """
  Resolves a bank denom into an `Asset`.

  Token-factory (`x/`) denoms and the THOR layer-1 denoms (`rune`, `tcy`,
  `thor.<symbol>`) are recognised by name. Everything else must be a lowercase
  `<chain><delimiter><symbol>` string — `-` secured, `/` synth, `~` trade — where
  the chain is alphabetic and the symbol alphanumeric with at most one `-<id>`
  suffix. That validation is what keeps `x/btc-btc` a token-factory denom rather
  than a secured asset.

  A staking receipt `x/staking-<bond denom>` takes its symbol from the bond denom
  (`sRUNE`); when the bond denom is not recognised it resolves as a plain
  token-factory denom rather than failing.

  Asset ids such as `BTC.BTC` are not denoms; use `from_string/1` for those.
  """
  @spec from_denom(String.t()) :: {:ok, Asset.t()} | {:error, :invalid_denom}
  def from_denom("x/ruji") do
    {:ok, %Asset{id: "THOR.RUJI", type: :native, chain: "THOR", symbol: "RUJI", ticker: "RUJI"}}
  end

  def from_denom("x/staking-" <> id = denom), do: build_staking(from_denom(id), denom)

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

  def from_denom("x/" <> _ = denom), do: {:ok, token_factory(denom)}

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

  def from_denom(denom), do: build_denom(Regex.run(@denom_regex, denom), denom)

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

  # --- Private ---

  defp build_asset(id) do
    %Asset{
      id: id,
      type: type(id),
      chain: chain(id),
      symbol: symbol(id),
      ticker: ticker(id)
    }
  end

  defp validate_id(true, id), do: {:ok, from_string(id)}
  defp validate_id(false, _id), do: {:error, :invalid_asset_id}

  defp build_denom(nil, _denom), do: {:error, :invalid_denom}

  defp build_denom([_, chain, _delimiter, symbol], denom) do
    id = String.upcase(denom)
    [ticker | _] = String.split(symbol, "-")

    {:ok,
     %Asset{
       id: id,
       type: type(id),
       chain: String.upcase(chain),
       symbol: String.upcase(symbol),
       ticker: String.upcase(ticker)
     }}
  end

  defp build_staking({:ok, staked}, denom) do
    {:ok,
     %Asset{
       id: denom,
       type: :native,
       chain: "THOR",
       symbol: "s" <> staked.symbol,
       ticker: "s" <> staked.ticker
     }}
  end

  # The staking contract mints `x/staking-{bond_denom}` for any bond denom, so an
  # unrecognised bond denom falls back to a plain token-factory asset.
  defp build_staking({:error, _}, denom), do: {:ok, token_factory(denom)}

  defp token_factory("x/" <> id = denom) do
    %Asset{
      id: denom,
      type: :native,
      chain: "THOR",
      symbol: String.upcase(id),
      ticker: String.upcase(id)
    }
  end
end
