defmodule Rujira.Fin.Pair do
  @moduledoc """
  Trading pair for the FIN protocol.

  Struct, construction, and queries. Use `Rujira.Fin` as the public API.
  """

  alias Rujira.Assets
  alias Rujira.Assets.Asset
  alias Rujira.Contracts
  alias Rujira.Deployments
  alias Rujira.Fin.Book
  alias Rujira.Math
  alias Rujira.Node
  alias Rujira.Thorchain.Oracle

  use Memoize

  # --- Struct ---

  defstruct id: nil,
            address: nil,
            market_makers: [],
            asset_base: nil,
            asset_quote: nil,
            oracle_base: nil,
            oracle_quote: nil,
            tick: 0,
            fee_taker: Decimal.new(0),
            fee_maker: Decimal.new(0),
            fee_address: nil,
            book: :not_loaded

  @type t :: %__MODULE__{
          id: String.t() | nil,
          address: String.t() | nil,
          market_makers: [String.t()],
          asset_base: Asset.t() | nil,
          asset_quote: Asset.t() | nil,
          oracle_base: Oracle.t() | nil,
          oracle_quote: Oracle.t() | nil,
          tick: integer(),
          fee_taker: Decimal.t(),
          fee_maker: Decimal.t(),
          fee_address: String.t() | nil,
          book: :not_loaded | Book.t()
        }

  # --- Construction ---

  @spec new(map()) :: {:ok, t()} | {:error, term()}

  def new(%{"market_maker" => nil} = attrs) do
    attrs |> Map.delete("market_maker") |> Map.put("market_makers", []) |> new()
  end

  def new(%{"market_maker" => market_maker} = attrs) do
    attrs |> Map.delete("market_maker") |> Map.put("market_makers", [market_maker]) |> new()
  end

  def new(%{
        "address" => address,
        "market_makers" => market_makers,
        "denoms" => denoms,
        "oracles" => oracles,
        "tick" => tick,
        "fee_taker" => fee_taker,
        "fee_maker" => fee_maker,
        "fee_address" => fee_address
      }) do
    with {:ok, fee_taker} <- Math.to_decimal(fee_taker),
         {:ok, fee_maker} <- Math.to_decimal(fee_maker),
         {:ok, asset_base} <- Assets.from_denom(Enum.at(denoms, 0)),
         {:ok, asset_quote} <- Assets.from_denom(Enum.at(denoms, 1)),
         {:ok, oracle_base} <- oracle_from_config(Enum.at(oracles || [], 0)),
         {:ok, oracle_quote} <- oracle_from_config(Enum.at(oracles || [], 1)) do
      {:ok,
       %__MODULE__{
         id: address,
         address: address,
         market_makers: market_makers,
         asset_base: asset_base,
         asset_quote: asset_quote,
         oracle_base: oracle_base,
         oracle_quote: oracle_quote,
         tick: tick,
         fee_taker: fee_taker,
         fee_maker: fee_maker,
         fee_address: fee_address,
         book: :not_loaded
       }}
    end
  end

  # --- Queries ---

  @spec get(String.t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def get(address, opts \\ []), do: Contracts.get({__MODULE__, address}, opts)

  @doc """
  Memoized list of all configured FIN pairs.

  Invalidate with `Memoize.invalidate(Rujira.Fin.Pair, :list)`.
  """
  @spec list() :: {:ok, [t()]} | {:error, term()}
  defmemo list do
    fetch_list([])
  end

  @doc """
  As `list/0`, read at `opts[:height]` when one is given - a height read is never
  cached. Without a `:height` this is `list/0`, so the other opts are not applied.
  """
  @spec list(Node.opts()) :: {:ok, [t()]} | {:error, term()}
  def list(opts), do: Node.at_height(opts, fn -> fetch_list(opts) end, &list/0)

  @spec find_stable(String.t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def find_stable(base_denom, opts \\ []) do
    with {:ok, pairs} <- list(opts),
         %__MODULE__{} = pair <- Enum.find(pairs, &stable_pair?(&1, base_denom)) do
      {:ok, pair}
    else
      nil -> {:error, :not_found}
      err -> err
    end
  end

  @doc """
  Finds the default pair for a base denom: prefers a stable (usdc/usdt) quote,
  otherwise falls back to the first pair quoting that base.
  """
  @spec find_default(String.t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def find_default(base_denom, opts \\ []) do
    with {:ok, pairs} <- list(opts) do
      pick_default(pairs, base_denom)
    end
  end

  @doc false
  @spec pick_default([t()], String.t()) :: {:ok, t()} | {:error, :not_found}
  def pick_default(pairs, base_denom) do
    stable = Enum.find(pairs, &stable_pair?(&1, base_denom))
    first = Enum.find(pairs, &base_denom?(&1, base_denom))

    case stable || first do
      %__MODULE__{} = pair -> {:ok, pair}
      nil -> {:error, :not_found}
    end
  end

  defp stable_pair?(%__MODULE__{asset_quote: %Asset{} = asset_quote} = pair, base_denom) do
    with true <- base_denom?(pair, base_denom),
         {:ok, quote_denom} <- Assets.to_native(asset_quote) do
      String.contains?(quote_denom, "usdc") or String.contains?(quote_denom, "usdt")
    else
      _ -> false
    end
  end

  defp stable_pair?(_, _), do: false

  defp base_denom?(%__MODULE__{asset_base: asset_base}, base_denom),
    do: Assets.to_native(asset_base) == {:ok, base_denom}

  @doc """
  Memoized lookup of the preferred base denom for a ticker.

  Invalidate with `Memoize.invalidate(Rujira.Fin.Pair, :denom_for_ticker, [ticker])`.
  """
  @spec denom_for_ticker(String.t()) :: {:ok, String.t()} | {:error, :not_found}
  defmemo denom_for_ticker(ticker) do
    fetch_denom_for_ticker(ticker, [])
  end

  @doc """
  As `denom_for_ticker/1`, read at `opts[:height]` when one is given - a height
  read is never cached.
  """
  @spec denom_for_ticker(String.t(), Node.opts()) :: {:ok, String.t()} | {:error, :not_found}
  def denom_for_ticker(ticker, opts) do
    Node.at_height(
      opts,
      fn -> fetch_denom_for_ticker(ticker, opts) end,
      fn -> denom_for_ticker(ticker) end
    )
  end

  @doc false
  @spec pick_denom([String.t()], String.t()) :: {:ok, String.t()} | {:error, :not_found}
  def pick_denom(denoms, ticker) do
    denoms
    |> Enum.uniq()
    |> Enum.flat_map(fn denom ->
      case Assets.from_denom(denom) do
        {:ok, %{ticker: ^ticker} = asset} -> [{denom, asset}]
        _ -> []
      end
    end)
    |> Enum.sort_by(fn {_, %{chain: chain}} -> chain != "ETH" end)
    |> case do
      [{denom, _} | _] -> {:ok, denom}
      [] -> {:error, :not_found}
    end
  end

  @doc """
  Memoized pair lookup by base + quote denom.

  Invalidate with `Memoize.invalidate(Rujira.Fin.Pair, :find_by_denoms, [base, quote])`.
  """
  @spec find_by_denoms(String.t(), String.t()) :: {:ok, t()} | {:error, term()}
  defmemo find_by_denoms(base_denom, quote_denom) do
    fetch_find_by_denoms(base_denom, quote_denom, [])
  end

  @doc """
  As `find_by_denoms/2`, read at `opts[:height]` when one is given - a height
  read is never cached.
  """
  @spec find_by_denoms(String.t(), String.t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def find_by_denoms(base_denom, quote_denom, opts) do
    Node.at_height(
      opts,
      fn -> fetch_find_by_denoms(base_denom, quote_denom, opts) end,
      fn -> find_by_denoms(base_denom, quote_denom) end
    )
  end

  @spec from_id(String.t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def from_id(id, opts \\ [])
  def from_id("sthor" <> _ = address, opts), do: get(address, opts)
  def from_id("thor" <> _ = address, opts), do: get(address, opts)

  def from_id(assets, opts) do
    with {:ok, pair} <- lookup(assets, opts) do
      {:ok, %{pair | id: assets}}
    end
  end

  @spec ticker_id!(t()) :: String.t()
  def ticker_id!(%__MODULE__{asset_base: asset_base, asset_quote: asset_quote}) do
    "#{Assets.label(asset_base)}_#{Assets.label(asset_quote)}"
  end

  # --- Private ---

  # A pair that cannot be read is not silently left out of the list: the list is
  # the set of configured pairs, so a pair missing from it would read as a pair
  # that does not exist.
  defp fetch_list(opts) do
    with {:ok, targets} <- Deployments.list_targets(__MODULE__, opts) do
      Rujira.Enum.reduce_while_ok(targets, &fetch_target(&1, opts))
    end
  end

  defp fetch_target(%{module: module, address: address}, opts),
    do: Contracts.get({module, address}, opts)

  defp fetch_denom_for_ticker(ticker, opts) do
    with {:ok, pairs} <- list(opts),
         {:ok, denoms} <-
           Rujira.Enum.reduce_while_ok(pairs, fn pair ->
             Assets.to_native(pair.asset_base)
           end) do
      pick_denom(denoms, ticker)
    end
  end

  defp fetch_find_by_denoms(base_denom, quote_denom, opts) do
    with {:ok, pairs} <- list(opts),
         %__MODULE__{} = pair <-
           Enum.find(
             pairs,
             &(base_denom?(&1, base_denom) and quote_denom?(&1, quote_denom))
           ) do
      {:ok, pair}
    else
      nil -> {:error, :not_found}
      err -> err
    end
  end

  defp quote_denom?(%__MODULE__{asset_quote: asset_quote}, quote_denom),
    do: Assets.to_native(asset_quote) == {:ok, quote_denom}

  defp oracle_from_config(%{"chain" => chain, "symbol" => symbol}) do
    id = String.upcase(chain) <> "." <> symbol
    asset = Assets.from_string(id)
    {:ok, %Oracle{id: id, ticker: asset.ticker, asset: asset}}
  end

  defp oracle_from_config(ticker) when is_binary(ticker) do
    {:ok, %Oracle{id: ticker, ticker: ticker, asset: nil}}
  end

  # An absent oracle is `nil`; a shape this does not know is an error rather than
  # a pair that reads as having no oracle.
  defp oracle_from_config(nil), do: {:ok, nil}
  defp oracle_from_config(_), do: {:error, :invalid_attrs}

  defp lookup(assets, opts) do
    with [b, q] <- String.split(assets, "/"),
         {:ok, pairs} <- list(opts),
         %__MODULE__{} = pair <-
           Enum.find(
             pairs,
             &(same_asset?(Assets.from_shortcode(b), &1.asset_base) and
                 same_asset?(Assets.from_shortcode(q), &1.asset_quote))
           ) do
      {:ok, pair}
    else
      nil -> {:error, :not_found}
      {:error, _} = err -> err
      _ -> {:error, :invalid_id}
    end
  end

  # The chain is THORChain's own uppercase name, but a ticker is spelled as the
  # token spells it (`bRUNE`, `sRUJI`, `yRUNE`), and an asset-form id is typed by
  # hand - so the chain matches exactly and the ticker case-insensitively.
  defp same_asset?(%Asset{chain: chain, ticker: a}, %Asset{chain: chain, ticker: b}),
    do: String.downcase(a) == String.downcase(b)

  defp same_asset?(_, _), do: false
end
