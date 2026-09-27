defmodule Rujira.Fin.Range do
  @moduledoc """
  Concentrated liquidity position (range) for the FIN protocol.

  FIN has two range implementations. This struct carries what they share —
  identity — with the implementation-specific state nested under `range:` as
  either a `Rujira.Fin.Range.Fixed` or a `Rujira.Fin.Range.Dynamic`.

  Both draw from a single on-chain index counter, so an `idx` identifies exactly
  one range of one kind within a pair — but not which kind. Queries therefore
  name the kind, and a dynamic range's `id` carries it: `<pair>/dynamic/<idx>`
  against `<pair>/<idx>` for a fixed one.

  Struct, construction, and queries. Use `Rujira.Fin` as the public API.
  """

  alias Rujira.Contracts
  alias Rujira.Fin.Pair
  alias Rujira.Fin.Range.Dynamic
  alias Rujira.Fin.Range.Fixed
  alias Rujira.Math
  alias Rujira.Node

  use Memoize

  @max_limit 100

  # --- Struct ---

  defstruct id: nil,
            idx: nil,
            pair: nil,
            owner: nil,
            range: nil

  @type t :: %__MODULE__{
          id: String.t() | nil,
          idx: integer() | nil,
          pair: String.t() | nil,
          owner: String.t() | nil,
          range: Fixed.t() | Dynamic.t() | nil
        }

  # --- Construction ---

  @doc """
  Parses a range from a contract query response.

  The response shapes are an untagged union, so the arm is selected on a key
  unique to each: `aep` for a dynamic range, `high` for a fixed one.
  """
  @spec new(Pair.t(), map()) :: {:ok, t()} | {:error, term()}
  def new(%{address: address}, attrs), do: build(address, attrs)
  def new(_, _), do: {:error, :invalid_attrs}

  # --- Queries ---

  @doc """
  Lists every range on a pair, of both kinds.

  Fixed and dynamic ranges are separately paginated on-chain, so this issues one
  query per kind. A contract that only has fixed ranges contributes those alone —
  see `query_dynamic_ranges/2`.
  """
  @spec list(Pair.t(), String.t() | nil, integer() | nil, Node.opts()) ::
          {:ok, [t()]} | {:error, term()}
  def list(pair, owner \\ nil, limit \\ nil, opts \\ []) do
    with {:ok, fixed} <- query_ranges(pair.address, owner, opts),
         {:ok, dynamic} <- query_dynamic_ranges(pair.address, owner, opts) do
      (fixed ++ dynamic)
      |> take(limit)
      |> Rujira.Enum.reduce_while_ok(&new(pair, &1))
    end
  end

  @doc """
  Loads a single range of a named kind.

  A bare `idx` is a fixed range, `{:dynamic, idx}` a dynamic one — the index
  alone does not say which, so the caller names it. An index the named kind does
  not hold is `{:error, :not_found}`.
  """
  @spec load(Pair.t(), integer() | {:dynamic, integer()}, Node.opts()) ::
          {:ok, t()} | {:error, term()}
  def load(%{address: address}, idx, opts \\ []), do: load_at(address, idx, opts)

  @spec list_all(String.t() | nil, [String.t()] | nil, Node.opts()) ::
          {:ok, [t()]} | {:error, term()}
  def list_all(owner \\ nil, contracts \\ nil, opts \\ []) do
    with {:ok, pairs} <- resolve_pairs(contracts, opts) do
      collect(pairs, owner, opts)
    end
  end

  @doc """
  Loads the range an `id` names, reading only the contract the id carries.

  The id is `<pair>/<idx>` for a fixed range and `<pair>/dynamic/<idx>` for a
  dynamic one — the pair's own config is not read, since a range is built from
  the range query alone.
  """
  @spec from_id(String.t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def from_id(id, opts \\ []), do: id |> String.split("/") |> load_parts(opts)

  @doc """
  Memoized full fetch of fixed ranges on a contract, optionally filtered by `owner`.

  Returns the flat list of raw range maps from the chain, paginated internally.
  Invalidate with `Memoize.invalidate(Rujira.Fin.Range, :query_ranges, [contract, owner])`.
  """
  @spec query_ranges(String.t(), String.t() | nil) :: {:ok, [map()]} | {:error, term()}
  defmemo query_ranges(contract, owner) do
    query_ranges_page(contract, owner, nil, [])
  end

  @doc """
  As `query_ranges/2`, read at `opts[:height]` when one is given - a height read
  is never cached. Without a `:height` this is `query_ranges/2`, so the other
  opts are not applied.
  """
  @spec query_ranges(String.t(), String.t() | nil, Node.opts()) ::
          {:ok, [map()]} | {:error, term()}
  def query_ranges(contract, owner, opts) do
    Node.at_height(
      opts,
      fn -> query_ranges_page(contract, owner, nil, opts) end,
      fn -> query_ranges(contract, owner) end
    )
  end

  @doc """
  Memoized full fetch of dynamic ranges on a contract, optionally filtered by `owner`.

  Dynamic ranges are an addition to FIN. A build that only has fixed ones does
  not reject this query — it ignores the `dynamic` selector and answers with
  fixed ranges — so the response is kept to the dynamic shape and such a
  contract reads as having none, which is what it has.

  Invalidate with `Memoize.invalidate(Rujira.Fin.Range, :query_dynamic_ranges, [contract, owner])`.
  """
  @spec query_dynamic_ranges(String.t(), String.t() | nil) :: {:ok, [map()]} | {:error, term()}
  defmemo query_dynamic_ranges(contract, owner) do
    fetch_dynamic_ranges(contract, owner, [])
  end

  @doc """
  As `query_dynamic_ranges/2`, read at `opts[:height]` when one is given - a
  height read is never cached. Without a `:height` this is
  `query_dynamic_ranges/2`, so the other opts are not applied.
  """
  @spec query_dynamic_ranges(String.t(), String.t() | nil, Node.opts()) ::
          {:ok, [map()]} | {:error, term()}
  def query_dynamic_ranges(contract, owner, opts) do
    Node.at_height(
      opts,
      fn -> fetch_dynamic_ranges(contract, owner, opts) end,
      fn -> query_dynamic_ranges(contract, owner) end
    )
  end

  @doc """
  Memoized fetch of a single fixed range by `idx` on a contract.

  Invalidate with `Memoize.invalidate(Rujira.Fin.Range, :query, [address, idx])`.
  """
  @spec query(String.t(), integer()) :: {:ok, map()} | {:error, term()}
  defmemo query(address, idx) do
    fetch_range(address, idx, [])
  end

  @doc """
  As `query/2`, read at `opts[:height]` when one is given - a height read is
  never cached. Without a `:height` this is `query/2`, so the other opts are not
  applied.
  """
  @spec query(String.t(), integer(), Node.opts()) :: {:ok, map()} | {:error, term()}
  def query(address, idx, opts) do
    Node.at_height(
      opts,
      fn -> fetch_range(address, idx, opts) end,
      fn -> query(address, idx) end
    )
  end

  @doc """
  Memoized fetch of a single dynamic range by `idx` on a contract.

  Invalidate with `Memoize.invalidate(Rujira.Fin.Range, :query_dynamic, [address, idx])`.
  """
  @spec query_dynamic(String.t(), integer()) :: {:ok, map()} | {:error, term()}
  defmemo query_dynamic(address, idx) do
    fetch_dynamic_range(address, idx, [])
  end

  @doc """
  As `query_dynamic/2`, read at `opts[:height]` when one is given - a height read
  is never cached. Without a `:height` this is `query_dynamic/2`, so the other
  opts are not applied.
  """
  @spec query_dynamic(String.t(), integer(), Node.opts()) :: {:ok, map()} | {:error, term()}
  def query_dynamic(address, idx, opts) do
    Node.at_height(
      opts,
      fn -> fetch_dynamic_range(address, idx, opts) end,
      fn -> query_dynamic(address, idx) end
    )
  end

  # --- Private ---

  defp build(address, %{"aep" => _} = attrs), do: build(address, attrs, Dynamic)
  defp build(address, %{"high" => _} = attrs), do: build(address, attrs, Fixed)
  defp build(_, _), do: {:error, :invalid_attrs}

  defp build(address, %{"idx" => idx, "owner" => owner} = attrs, variant) do
    with {:ok, idx} <- Math.to_integer(idx),
         {:ok, range} <- variant.new(attrs) do
      {:ok,
       %__MODULE__{
         id: id(address, idx, variant),
         idx: idx,
         pair: address,
         owner: owner,
         range: range
       }}
    end
  end

  defp build(_, _, _), do: {:error, :invalid_attrs}

  defp load_at(address, {:dynamic, idx}, opts),
    do: loaded(address, query_dynamic(address, idx, opts))

  defp load_at(address, idx, opts), do: loaded(address, query(address, idx, opts))

  defp load_parts([address, "dynamic", idx], opts),
    do: load_part(address, idx, &{:dynamic, &1}, opts)

  defp load_parts([address, idx], opts), do: load_part(address, idx, & &1, opts)
  defp load_parts(_, _), do: {:error, :invalid_id}

  defp load_part(address, idx, kind, opts) do
    with {:ok, idx} <- Math.to_integer(idx) do
      load_at(address, kind.(idx), opts)
    end
  end

  # A range the contract does not hold is `:not_found`. Every other error is the
  # contract's or the node's, and is handed back unchanged.
  defp loaded(address, {:ok, range}), do: build(address, range)
  defp loaded(_address, {:error, err}), do: missing(Contracts.not_found?(err), err)

  defp missing(true, _err), do: {:error, :not_found}
  defp missing(false, err), do: {:error, err}

  # A dynamic range's id names its kind, so it round-trips through `from_id/1`
  # to the query that can actually find it.
  defp id(address, idx, Dynamic), do: "#{address}/dynamic/#{idx}"
  defp id(address, idx, Fixed), do: "#{address}/#{idx}"

  defp resolve_pairs(nil, opts), do: Pair.list(opts)

  defp resolve_pairs(contracts, opts) when is_list(contracts),
    do: Rujira.Enum.reduce_while_ok(contracts, &Pair.get(&1, opts))

  defp collect(pairs, owner, opts) do
    with {:ok, ranges} <-
           Rujira.Enum.reduce_async_while_ok(pairs, &list(&1, owner, nil, opts), timeout: 15_000) do
      {:ok, List.flatten(ranges)}
    end
  end

  defp take(ranges, nil), do: ranges
  defp take(ranges, n), do: Enum.take(ranges, n)

  defp fetch_range(address, idx, opts) do
    Contracts.query_state_smart(address, %{range: Kernel.to_string(idx)}, opts)
  end

  defp fetch_dynamic_range(address, idx, opts) do
    Contracts.query_state_smart(address, %{range: %{dynamic: Kernel.to_string(idx)}}, opts)
  end

  defp fetch_dynamic_ranges(contract, owner, opts) do
    with {:ok, ranges} <- query_dynamic_ranges_page(contract, owner, nil, opts) do
      {:ok, Enum.filter(ranges, &Map.has_key?(&1, "aep"))}
    end
  end

  defp query_ranges_page(contract, owner, cursor, opts) do
    contract
    |> Contracts.query_state_smart_with_retry(
      %{ranges: %{owner: owner, cursor: cursor, limit: @max_limit}},
      opts
    )
    |> Contracts.paginate("ranges", @max_limit, fn ranges ->
      query_ranges_page(contract, owner, ranges |> List.last() |> Map.get("idx"), opts)
    end)
  end

  defp query_dynamic_ranges_page(contract, owner, cursor, opts) do
    contract
    |> Contracts.query_state_smart_with_retry(
      %{ranges: %{dynamic: %{owner: owner, cursor: cursor, limit: @max_limit}}},
      opts
    )
    |> Contracts.paginate("ranges", @max_limit, fn ranges ->
      query_dynamic_ranges_page(contract, owner, Map.get(List.last(ranges), "idx"), opts)
    end)
  end
end
