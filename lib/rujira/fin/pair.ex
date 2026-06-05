defmodule Rujira.Fin.Pair do
  @moduledoc """
  Trading pair for the FIN protocol.

  Struct, construction, and queries. Use `Rujira.Fin` as the public API.
  """

  alias Rujira.Assets
  alias Rujira.Contracts
  alias Rujira.Deployments
  alias Rujira.Fin.Book
  alias Rujira.Logger
  alias Rujira.Math
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

  @spec get(String.t()) :: {:ok, t()} | {:error, term()}
  def get(address), do: Contracts.get({__MODULE__, address})

  @doc """
  Memoized list of all configured FIN pairs.

  Invalidate with `Memoize.invalidate(Rujira.Fin.Pair, :list)`.
  """
  @spec list() :: {:ok, [t()]} | {:error, term()}
  defmemo list do
    targets = Deployments.list_targets(__MODULE__)

    Rujira.Enum.reduce_while_ok(targets, [], fn %{module: module, address: address} ->
      case Contracts.get({module, address}) do
        {:ok, v} ->
          {:ok, v}

        {:error, err} ->
          Logger.error(__MODULE__, "#{address} error #{inspect(err)}")
          :skip
      end
    end)
  end

  @spec find_stable(String.t()) :: {:ok, t()} | {:error, term()}
  def find_stable(base_denom) do
    with {:ok, pairs} <- list(),
         %__MODULE__{} = pair <-
           Enum.find(
             pairs,
             &(&1.token_base == base_denom &&
                 (String.contains?(&1.token_quote, "usdc") ||
                    String.contains?(&1.token_quote, "usdt")))
           ) do
      {:ok, pair}
    else
      nil -> {:error, :not_found}
      err -> err
    end
  end

  @doc """
  Memoized lookup of the preferred base denom for a ticker.

  Invalidate with `Memoize.invalidate(Rujira.Fin.Pair, :denom_for_ticker, [ticker])`.
  """
  @spec denom_for_ticker(String.t()) :: {:ok, String.t()} | {:error, :not_found}
  defmemo denom_for_ticker(ticker) do
    with {:ok, pairs} <- list() do
      pairs |> Enum.map(& &1.token_base) |> pick_denom(ticker)
    end
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
    with {:ok, pairs} <- list(),
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

  @spec from_id(String.t()) :: {:ok, t()} | {:error, term()}
  def from_id("sthor" <> _ = address), do: get(address)
  def from_id("thor" <> _ = address), do: get(address)

  def from_id(assets) do
    with {:ok, pair} <- lookup(assets) do
      {:ok, %{pair | id: assets}}
    end
  end

  @spec ticker_id!(t()) :: String.t()
  def ticker_id!(%__MODULE__{token_base: token_base, token_quote: token_quote}) do
    {:ok, base} = Assets.from_denom(token_base)
    {:ok, target} = Assets.from_denom(token_quote)

    "#{Assets.label(base)}_#{Assets.label(target)}"
  end

  @spec tvl(String.t()) :: {:ok, non_neg_integer()} | {:error, term()}
  def tvl(address) do
    case get(address) do
      {:ok, %__MODULE__{market_makers: mms} = pair} ->
        mm_tvl = mms |> Enum.map(&mm_tvl/1) |> Enum.sum()

        case Rujira.Fin.Range.tvl(pair) do
          {:ok, r_tvl} -> {:ok, mm_tvl + r_tvl}
          {:error, _} = err -> err
        end

      _ ->
        {:ok, 0}
    end
  end

  # --- Private ---

  defp oracle_from_config(%{"chain" => chain, "symbol" => symbol}) do
    id = String.upcase(chain) <> "." <> symbol
    {:ok, %Oracle{id: id, symbol: id, asset: Assets.from_string(id)}}
  end

  defp oracle_from_config(nil), do: {:ok, nil}

  defp mm_tvl(mm) do
    with {:ok, %Deployments.Target{module: module}} <- Deployments.from_address(mm),
         {:ok, pool} <- module.pool_from_id(mm) do
      module.tvl(pool)
    else
      _ -> 0
    end
  end

  defp lookup(assets) do
    with [b, q] <- String.split(assets, "/"),
         {:ok, pairs} <- list(),
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
      _ -> {:error, :invalid_id}
    end
  end
end
