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

  @spec tvl(String.t(), Node.opts()) :: {:ok, non_neg_integer()} | {:error, term()}
  def tvl(address, opts \\ []) do
    case get(address, opts) do
      {:ok, %__MODULE__{market_makers: mms} = pair} ->
        with {:ok, mm_tvl} <- sum_mm_tvl(mms, opts),
             {:ok, r_tvl} <- Rujira.Fin.Range.tvl(pair, opts) do
          {:ok, mm_tvl + r_tvl}
        end

      {:error, err} ->
        unless_height_error(err, fn -> {:ok, 0} end)
    end
  end

  # --- Private ---

  defp fetch_list(opts) do
    with {:ok, targets} <- Deployments.list_targets(__MODULE__, opts) do
      Rujira.Enum.reduce_while_ok(targets, [], &fetch_target(&1, opts))
    end
  end

  # One pair that cannot be read must not fail the whole list - except when the
  # height itself could not be served, which no skip can stand in for.
  defp fetch_target(%{module: module, address: address}, opts) do
    case Contracts.get({module, address}, opts) do
      {:ok, v} ->
        {:ok, v}

      {:error, err} ->
        unless_height_error(err, fn ->
          Logger.error(__MODULE__, "#{address} error #{inspect(err)}")
          :skip
        end)
    end
  end

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

  defp oracle_from_config(nil), do: {:ok, nil}
  defp oracle_from_config(_), do: {:ok, nil}

  # A market maker's TVL is a bare number, so it has no error channel of its
  # own: a height that could not be served surfaces as an error on either the
  # `Deployments.from_address/2` lookup or the market maker's own state query,
  # both made at that same height. Any other failure keeps contributing 0, as
  # before.
  defp mm_tvl(mm, opts) do
    with {:ok, %Deployments.Target{module: module}} <- Deployments.from_address(mm, opts),
         {:ok, pool} <- mm_call(module, :pool_from_id, [mm], opts),
         tvl when is_integer(tvl) <- mm_call(module, :tvl, [pool], opts) do
      {:ok, tvl}
    else
      {:error, err} -> unless_height_error(err, fn -> {:ok, 0} end)
      _ -> {:ok, 0}
    end
  end

  defp sum_mm_tvl(mms, opts) do
    Enum.reduce_while(mms, {:ok, 0}, fn mm, {:ok, acc} ->
      case mm_tvl(mm, opts) do
        {:ok, tvl} -> {:cont, {:ok, acc + tvl}}
        {:error, _} = err -> {:halt, err}
      end
    end)
  end

  # A market maker's module lives in the consumer, not here, so it may not have
  # taken `opts` yet. Call the opts arity when it exports one. The bare arity
  # reads the latest state, which is not the state at a requested height, so for
  # a height read an unconverted market maker is `{:error, :height_not_supported}`
  # — only a live read falls back to it, contributing its present TVL.
  defp mm_call(module, fun, args, opts) do
    Code.ensure_loaded(module)

    if function_exported?(module, fun, length(args) + 1) do
      apply(module, fun, args ++ [opts])
    else
      Node.at_height(
        opts,
        fn -> {:error, :height_not_supported} end,
        fn -> apply(module, fun, args) end
      )
    end
  end

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
      {:error, err} -> unless_height_error(err, fn -> {:error, :invalid_id} end)
      _ -> {:error, :invalid_id}
    end
  end

  # A height read that could not be served is an error, never a default: the
  # caller asked for the state at one height and must be told that height was
  # not read. Every other error keeps today's behaviour.
  defp unless_height_error({:height_unavailable, _} = err, _fallback), do: {:error, err}
  defp unless_height_error({:height_mismatch, _, _} = err, _fallback), do: {:error, err}
  defp unless_height_error(:invalid_height, _fallback), do: {:error, :invalid_height}
  defp unless_height_error(:height_not_supported, _fallback), do: {:error, :height_not_supported}
  defp unless_height_error(_err, fallback), do: fallback.()
end
