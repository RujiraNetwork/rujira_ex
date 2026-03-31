defmodule Rujira.Assets do
  @moduledoc """
  Asset resolution for Rujira protocol.

  Merges base-layer asset handling (chain/symbol/denom parsing) with
  app-layer token support (x/ruji, x/staking-*, x/bow-xyk-*, etc.).
  """

  alias Rujira.Assets.Asset
  alias Rujira.Assets.Metadata
  alias Thorchain.Types.Query.Stub, as: Q
  alias Thorchain.Types.QueryPoolsRequest

  @delimiters [".", "-", "/", "~"]
  @coin_regex ~r/^(\d+(?:\.\d+)?|\.\d+)\s*([a-zA-Z][a-zA-Z0-9\/:._-]{2,127})$/

  # --- Pool queries ---

  def assets do
    with {:ok, %{pools: pools}} <- Rujira.Node.query(&Q.pools/2, %QueryPoolsRequest{}) do
      Enum.map(pools, &from_string(&1.asset))
    end
  end

  def erc20(chain) do
    chain = chain |> Kernel.to_string() |> String.upcase()

    Enum.filter(
      assets(),
      &(&1.chain == chain && String.starts_with?(&1.symbol, "#{&1.ticker}-0X"))
    )
  end

  # --- Metadata ---

  def load_metadata(%Asset{id: "x/" <> _ = denom} = asset) do
    with {:ok, metadata} <- Metadata.load_metadata(denom) do
      {:ok, %{metadata | decimals: decimals(asset)}}
    end
  end

  def load_metadata(%Asset{ticker: ticker} = asset) do
    {:ok, %{symbol: ticker, decimals: decimals(asset)}}
  end

  # --- from_string ---

  def from_string(id) do
    %Asset{
      id: id,
      type: type(id),
      chain: chain(id),
      symbol: symbol(id),
      ticker: ticker(id)
    }
  end

  # --- from_shortcode ---

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

  def from_id(id), do: {:ok, from_string(id)}

  def to_string(%Asset{id: id}), do: id

  # --- chain/symbol/ticker ---

  def chain("x/" <> _), do: "THOR"

  def chain(str) do
    [c | _] = String.split(str, @delimiters)
    c
  end

  def symbol("x/" <> id), do: String.upcase(id)

  def symbol(str) do
    [_, v] = String.split(str, @delimiters, parts: 2)
    v
  end

  def ticker("x/" <> id), do: String.upcase(id)

  def ticker(str) do
    [_, v] = String.split(str, @delimiters, parts: 2)
    [sym | _] = String.split(v, "-")
    sym
  end

  # --- decimals ---

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

  def to_native(%Asset{} = a), do: to_secured(a) |> to_native()
  def to_native(nil), do: {:ok, nil}

  # --- to_layer1 / to_secured ---

  def to_layer1(%Asset{chain: "THOR"}), do: nil

  def to_layer1(%Asset{id: id} = a) do
    %{a | type: :layer_1, id: String.replace(id, ~r/[\.\-\/]/, ".", global: false)}
  end

  def to_secured(%Asset{chain: "THOR"}), do: nil

  def to_secured(%Asset{id: id} = a) do
    %{a | type: :secured, id: String.replace(id, ~r/[\.\-\/]/, "-", global: false)}
  end

  # --- from_denom (app-layer overrides first, then base-layer) ---

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

  def from_denom("x/bow-xyk-" <> id = denom) do
    # Generic fallback -- consumer can override via denom_resolver config
    case resolve_bow_denom(denom, id) do
      {:ok, _} = result -> result
      _ -> {:ok, generic_x_asset(denom, id)}
    end
  end

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
    {:ok, generic_x_asset(denom, id)}
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
        {:error, "Invalid Denom #{denom}"}
    end
  end

  # --- eq_denom ---

  def eq_denom(%Asset{} = a, denom) do
    case from_denom(denom) do
      {:ok, asset} -> a.chain == asset.chain and a.ticker == asset.ticker
      _ -> false
    end
  end

  # --- Display helpers ---

  def short_id(%{chain: chain, ticker: ticker}), do: "#{chain}.#{ticker}"

  def label(%{chain: "ETH", ticker: "USDC"}), do: "USDC"

  def label(%{chain: chain, ticker: ticker}) when ticker in ["USDC", "USDT"],
    do: "#{ticker}.#{chain}"

  def label(%{chain: chain, ticker: "ETH"}) when chain != "ETH", do: "ETH.#{chain}"
  def label(%{ticker: ticker}), do: ticker

  # --- Coin/asset parsing ---

  def parse_coins(str) do
    str
    |> String.split(",", trim: true)
    |> Enum.map(&Regex.run(@coin_regex, &1))
    |> Enum.reduce_while(%{}, fn
      [_, amount, denom], acc -> {:cont, Map.put(acc, denom, String.to_integer(amount))}
      _, _ -> {:halt, {:error, :invalid_denom_format}}
    end)
    |> case do
      {:error, _} = error -> error
      map -> {:ok, map}
    end
  end

  def parse_asset(<<>>), do: {:error, :invalid_asset}

  def parse_asset(asset_str) do
    case String.split(asset_str, " ", parts: 2) do
      [amount_str, asset] ->
        case Integer.parse(amount_str) do
          {amt, _} -> {:ok, {asset, amt}}
          :error -> {:error, :invalid_amount}
        end

      _ ->
        {:error, :invalid_asset}
    end
  end

  # --- Query matching ---

  def query_match(query, %{ticker: b}, %{ticker: q}) do
    case parse_query_parts(query) do
      [part] -> matches(part, b) or matches(part, q)
      [part1, part2] -> matches(part1, b) and matches(part2, q)
      _ -> true
    end
  end

  def matches(nil, _target), do: true
  def matches("*", _target), do: true

  def matches(query, target) when is_binary(target) do
    target |> String.downcase() |> String.contains?(String.downcase(query))
  end

  def matches(_query, _target), do: false

  # --- Primary grouping ---

  def primary(%Asset{type: :secured} = a), do: a
  def primary(%Asset{ticker: "ETH"}), do: from_string("ETH-ETH")
  def primary(%Asset{ticker: "WETH"}), do: from_string("ETH-ETH")
  def primary(%Asset{ticker: "WBTC"}), do: from_string("BTC-BTC")
  def primary(%Asset{ticker: "BTC"}), do: from_string("BTC-BTC")
  def primary(%Asset{ticker: "CBBTC"}), do: from_string("BTC-BTC")
  def primary(%Asset{ticker: "BTCB"}), do: from_string("BTC-BTC")

  def primary(%Asset{ticker: "USDC"}),
    do: from_string("ETH-USDC-0XA0B86991C6218B36C1D19D4A2E9EB0CE3606EB48")

  def primary(%Asset{ticker: "USDT"}),
    do: from_string("ETH-USDT-0XDAC17F958D2EE523A2206206994597C13D831EC7")

  def primary(%Asset{ticker: "AUTO"} = a), do: to_switch(a)
  def primary(%Asset{ticker: "FUZN"} = a), do: to_switch(a)
  def primary(%Asset{ticker: "KUJI"} = a), do: to_switch(a)
  def primary(%Asset{ticker: "LQDY"} = a), do: to_switch(a)
  def primary(%Asset{ticker: "LVN"} = a), do: to_switch(a)
  def primary(%Asset{ticker: "MNTA"} = a), do: to_switch(a)
  def primary(%Asset{ticker: "NAMI"} = a), do: to_switch(a)
  def primary(%Asset{ticker: "NSTK"} = a), do: to_switch(a)
  def primary(%Asset{ticker: "RKUJI"} = a), do: to_switch(a)
  def primary(%Asset{ticker: "WINK"} = a), do: to_switch(a)
  def primary(%Asset{chain: "THOR"} = a), do: a
  def primary(asset), do: to_secured(asset)

  def key(%Asset{type: :secured, id: id}), do: id
  def key(%Asset{} = a), do: a |> primary() |> Map.get(:id)

  def to_switch(%{ticker: ticker} = a),
    do: %{a | id: "THOR.#{ticker}", type: :native, chain: "THOR"}

  # --- Private ---

  defp parse_query_parts(nil), do: []
  defp parse_query_parts(""), do: []
  defp parse_query_parts(query), do: Regex.split(~r/[\s\-\/]/, query, trim: true)

  defp generic_x_asset(denom, id) do
    %Asset{
      id: denom,
      type: :native,
      chain: "THOR",
      symbol: String.upcase(id),
      ticker: String.upcase(id)
    }
  end

  defp resolve_bow_denom(denom, id) do
    case Application.get_env(:rujira_core, :denom_resolver) do
      nil -> {:ok, generic_x_asset(denom, id)}
      resolver -> resolver.resolve_bow_denom(denom, id)
    end
  end
end
