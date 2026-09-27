defmodule Rujira.Fin.Pair do
  @moduledoc """
  Trading pair for the FIN protocol.

  Struct, construction, and queries. Use `Rujira.Fin` as the public API.
  """

  alias Rujira.Assets
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
            token_base: nil,
            token_quote: nil,
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
          token_base: String.t() | nil,
          token_quote: String.t() | nil,
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
         {:ok, oracle_base} <- oracle_from_config(Enum.at(oracles || [], 0)),
         {:ok, oracle_quote} <- oracle_from_config(Enum.at(oracles || [], 1)) do
      {:ok,
       %__MODULE__{
         id: address,
         address: address,
         market_makers: market_makers,
         token_base: Enum.at(denoms, 0),
         token_quote: Enum.at(denoms, 1),
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
    first = Enum.find(pairs, &(&1.token_base == base_denom))

    case stable || first do
      %__MODULE__{} = pair -> {:ok, pair}
      nil -> {:error, :not_found}
    end
  end

  defp stable_pair?(%__MODULE__{token_base: base_denom, token_quote: quote}, base_denom)
       when is_binary(quote) do
    String.contains?(quote, "usdc") or String.contains?(quote, "usdt")
  end

  defp stable_pair?(_, _), do: false

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
  def ticker_id!(%__MODULE__{token_base: token_base, token_quote: token_quote}) do
    {:ok, base} = Assets.from_denom(token_base)
    {:ok, target} = Assets.from_denom(token_quote)

    "#{Assets.label(base)}_#{Assets.label(target)}"
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
    with {:ok, pairs} <- list(opts) do
      pairs |> Enum.map(& &1.token_base) |> pick_denom(ticker)
    end
  end

  defp fetch_find_by_denoms(base_denom, quote_denom, opts) do
    with {:ok, pairs} <- list(opts),
         %__MODULE__{} = pair <-
           Enum.find(
             pairs,
             &(&1.token_base == base_denom && &1.token_quote == quote_denom)
           ) do
      {:ok, pair}
    else
      nil -> {:error, :not_found}
      err -> err
    end
  end

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
             &(Assets.eq_denom(
                 Assets.from_shortcode(b),
                 &1.token_base
               ) and
                 Assets.eq_denom(
                   Assets.from_shortcode(q),
                   &1.token_quote
                 ))
           ) do
      {:ok, pair}
    else
      nil -> {:error, :not_found}
      {:error, _} = err -> err
      _ -> {:error, :invalid_id}
    end
  end
end
