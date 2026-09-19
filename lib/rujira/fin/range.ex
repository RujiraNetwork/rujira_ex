defmodule Rujira.Fin.Range do
  @moduledoc """
  Concentrated liquidity position (range) for the FIN protocol.

  FIN has two range implementations. This struct carries what they share —
  identity and USD value — with the implementation-specific state nested under
  `range:` as either a `Rujira.Fin.Range.Fixed` or a `Rujira.Fin.Range.Dynamic`.

  Both draw from a single on-chain index counter, so an `idx` identifies exactly
  one range of one kind within a pair.

  Struct, construction, and queries. Use `Rujira.Fin` as the public API.
  """

  alias Rujira.Amount
  alias Rujira.Assets
  alias Rujira.Contracts
  alias Rujira.Fin.Pair
  alias Rujira.Fin.Range.Dynamic
  alias Rujira.Fin.Range.Fixed
  alias Rujira.Math
  alias Rujira.Prices

  use Memoize

  @max_limit 100

  # --- Struct ---

  defstruct id: nil,
            idx: nil,
            pair: nil,
            owner: nil,
            value_usd: 0,
            range: nil

  @type t :: %__MODULE__{
          id: String.t() | nil,
          idx: integer() | nil,
          pair: String.t() | nil,
          owner: String.t() | nil,
          value_usd: Amount.t(),
          range: Fixed.t() | Dynamic.t() | nil
        }

  # --- Construction ---

  @doc """
  Parses a range from a contract query response.

  The response shapes are an untagged union, so the arm is selected on a key
  unique to each: `aep` for a dynamic range, `high` for a fixed one.
  """
  @spec new(Pair.t(), map()) :: {:ok, t()} | {:error, term()}
  def new(pair, %{"aep" => _} = attrs), do: build(pair, attrs, Dynamic)
  def new(pair, %{"high" => _} = attrs), do: build(pair, attrs, Fixed)
  def new(_, _), do: {:error, :invalid_attrs}

  # --- Queries ---

  @doc """
  Lists every range on a pair, of both kinds.

  Fixed and dynamic ranges are separately paginated on-chain, so this issues one
  query per kind.
  """
  @spec list(Pair.t(), String.t() | nil, integer() | nil) ::
          {:ok, [t()]} | {:error, term()}
  def list(pair, owner \\ nil, limit \\ nil) do
    with {:ok, fixed} <- query_ranges(pair.address, owner),
         {:ok, dynamic} <- query_dynamic_ranges(pair.address, owner) do
      (fixed ++ dynamic)
      |> take(limit)
      |> Rujira.Enum.reduce_while_ok(&new(pair, &1))
    end
  end

  @doc """
  Loads a single range by index.

  The kind isn't knowable from the index alone, so the fixed arm is tried first
  and the dynamic arm on miss. A range that is in neither returns a placeholder.
  """
  @spec load(Pair.t(), integer()) :: {:ok, t()} | {:error, term()}
  def load(%{address: address} = pair, idx) do
    case query(address, idx) do
      {:ok, range} ->
        new(pair, range)

      {:error, %GRPC.RPCError{status: 2, message: "NotFound: query wasm contract failed"}} ->
        load_dynamic(pair, idx)

      err ->
        err
    end
  end

  @spec list_all(String.t() | nil, [String.t()] | nil) :: {:ok, [t()]} | {:error, term()}
  def list_all(owner \\ nil, contracts \\ nil) do
    with {:ok, pairs} <- resolve_pairs(contracts) do
      collect(pairs, owner)
    end
  end

  @spec from_id(String.t()) :: {:ok, t()} | {:error, term()}
  def from_id(id) do
    with [pair_address, idx] <- String.split(id, "/"),
         {:ok, idx} <- Math.to_integer(idx),
         {:ok, pair} <- Pair.get(pair_address) do
      load(pair, idx)
    else
      {:error, _} = err -> err
      _ -> {:error, :invalid_id}
    end
  end

  @spec tvl(Pair.t()) :: {:ok, non_neg_integer()} | {:error, term()}
  def tvl(pair) do
    with {:ok, ranges} <- list(pair) do
      {:ok, Enum.sum_by(ranges, & &1.value_usd)}
    end
  end

  @spec total_tvl() :: {:ok, non_neg_integer()} | {:error, term()}
  def total_tvl do
    with {:ok, pairs} <- Pair.list(),
         {:ok, tvls} <-
           Rujira.Enum.reduce_async_while_ok(pairs, &tvl_or_zero/1, timeout: 30_000) do
      {:ok, Enum.sum(tvls)}
    end
  end

  @doc """
  Memoized full fetch of fixed ranges on a contract, optionally filtered by `owner`.

  Returns the flat list of raw range maps from the chain, paginated internally.
  Invalidate with `Memoize.invalidate(Rujira.Fin.Range, :query_ranges, [contract, owner])`.
  """
  @spec query_ranges(String.t(), String.t() | nil) :: {:ok, [map()]} | {:error, term()}
  defmemo query_ranges(contract, owner) do
    query_ranges_page(contract, owner, nil)
  end

  @doc """
  Memoized full fetch of dynamic ranges on a contract, optionally filtered by `owner`.

  Invalidate with `Memoize.invalidate(Rujira.Fin.Range, :query_dynamic_ranges, [contract, owner])`.
  """
  @spec query_dynamic_ranges(String.t(), String.t() | nil) :: {:ok, [map()]} | {:error, term()}
  defmemo query_dynamic_ranges(contract, owner) do
    query_dynamic_ranges_page(contract, owner, nil)
  end

  @doc """
  Memoized fetch of a single fixed range by `idx` on a contract.

  Invalidate with `Memoize.invalidate(Rujira.Fin.Range, :query, [address, idx])`.
  """
  @spec query(String.t(), integer()) :: {:ok, map()} | {:error, term()}
  defmemo query(address, idx) do
    Contracts.query_state_smart(address, %{range: Kernel.to_string(idx)})
  end

  @doc """
  Memoized fetch of a single dynamic range by `idx` on a contract.

  Invalidate with `Memoize.invalidate(Rujira.Fin.Range, :query_dynamic, [address, idx])`.
  """
  @spec query_dynamic(String.t(), integer()) :: {:ok, map()} | {:error, term()}
  defmemo query_dynamic(address, idx) do
    Contracts.query_state_smart(address, %{range: %{dynamic: Kernel.to_string(idx)}})
  end

  # --- Private ---

  defp build(
         %{address: address, token_quote: token_quote, token_base: token_base},
         %{"idx" => idx, "owner" => owner} = attrs,
         variant
       ) do
    with {:ok, asset_quote} <- Assets.from_denom(token_quote),
         {:ok, asset_base} <- Assets.from_denom(token_base),
         {:ok, idx} <- Math.to_integer(idx),
         {:ok, range} <- variant.new(attrs) do
      {:ok,
       %__MODULE__{
         id: "#{address}/#{idx}",
         idx: idx,
         pair: address,
         owner: owner,
         value_usd: value_usd(asset_base, asset_quote, range),
         range: range
       }}
    end
  end

  defp build(_, _, _), do: {:error, :invalid_attrs}

  defp load_dynamic(%{address: address} = pair, idx) do
    case query_dynamic(address, idx) do
      {:ok, range} ->
        new(pair, range)

      {:error, %GRPC.RPCError{status: 2, message: "NotFound: query wasm contract failed"}} ->
        {:ok, placeholder(address, idx)}

      err ->
        err
    end
  end

  defp placeholder(address, idx) do
    %__MODULE__{id: "#{address}/#{idx}", idx: idx, pair: address}
  end

  defp resolve_pairs(nil), do: Pair.list()

  defp resolve_pairs(contracts) when is_list(contracts),
    do: Rujira.Enum.reduce_while_ok(contracts, &Pair.get/1)

  defp collect(pairs, owner) do
    with {:ok, ranges} <-
           Rujira.Enum.reduce_async_while_ok(pairs, &list(&1, owner), timeout: 15_000) do
      {:ok, List.flatten(ranges)}
    end
  end

  defp tvl_or_zero(pair) do
    case tvl(pair) do
      {:ok, _} = ok -> ok
      {:error, _} -> {:ok, 0}
    end
  end

  defp take(ranges, nil), do: ranges
  defp take(ranges, n), do: Enum.take(ranges, n)

  defp value_usd(asset_base, asset_quote, range) do
    {base, quote_} = totals(range)

    Prices.value_usd(asset_base.ticker, base) +
      Prices.value_usd(asset_quote.ticker, quote_)
  end

  defp totals(%Fixed{} = range), do: Fixed.totals(range)
  defp totals(%Dynamic{} = range), do: Dynamic.totals(range)

  defp query_ranges_page(contract, owner, cursor) do
    contract
    |> Contracts.query_state_smart_with_retry(%{
      ranges: %{owner: owner, cursor: cursor, limit: @max_limit}
    })
    |> Contracts.paginate("ranges", @max_limit, fn ranges ->
      query_ranges_page(contract, owner, List.last(ranges)["idx"])
    end)
  end

  defp query_dynamic_ranges_page(contract, owner, cursor) do
    contract
    |> Contracts.query_state_smart_with_retry(%{
      ranges: %{dynamic: %{owner: owner, cursor: cursor, limit: @max_limit}}
    })
    |> Contracts.paginate("ranges", @max_limit, fn ranges ->
      query_dynamic_ranges_page(contract, owner, List.last(ranges)["idx"])
    end)
  end
end
