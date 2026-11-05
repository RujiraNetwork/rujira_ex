defmodule Rujira.Ghost.Vault.Borrower do
  @moduledoc """
  A whitelisted borrower's position on a Ghost vault.

  Struct, construction, and queries. Use `Rujira.Ghost` as the public API.

  Parses every shape the vault's `borrower` and `borrowers` queries have
  served, which are also the entries of the credit contract's `borrows`
  query (`Rujira.Ghost.Credit`, from credit v1.0.0) and the `borrower` of a
  `Rujira.Ghost.Vault.Delegate`. A vault read at an older height serves the
  shape of the code it ran then. Fields a shape does not carry are `nil`:

  | Shape | Contract          | Upstream             | `available` | `asset` (`denom`) | `shares` on the wire |
  | ----- | ----------------- | -------------------- | ----------- | ----------------- | -------------------- |
  | B0    | v0.0.1            | `787e63b`            | `nil`       | `nil`             | `Uint128`            |
  | B1    | v0.1.0 to v0.1.2  | `1c784ec`..`fbf80aa` | set         | `nil`             | `Uint128`            |
  | B2    | v1.0.0 to v1.0.8  | `355aafa`..`9264370` | set         | set               | `Uint128`            |
  | B3    | v1.1.0 and later  | `3ee2d68`+           | set         | set               | `Decimal`            |

  `shares` is a `Decimal` on every shape, since an integer string parses as
  one. The `borrowers` envelope (`{"borrowers": [...]}`) and the credit
  contract's `borrows` envelope have not changed.
  """

  alias Rujira.Amount
  alias Rujira.Assets
  alias Rujira.Assets.Asset
  alias Rujira.Cache
  alias Rujira.Contracts
  alias Rujira.Math
  alias Rujira.Node

  @max_limit 100

  # --- Struct ---

  defstruct address: nil,
            asset: nil,
            limit: 0,
            current: 0,
            shares: Decimal.new(0),
            available: nil

  @type t :: %__MODULE__{
          address: String.t() | nil,
          asset: Asset.t() | nil,
          limit: Amount.t(),
          current: Amount.t(),
          shares: Decimal.t(),
          available: Amount.t() | nil
        }

  # --- Construction ---

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"denom" => denom, "available" => available} = attrs) do
    with {:ok, asset} <- Assets.from_denom(denom),
         {:ok, available} <- Amount.new(available) do
      build(attrs, asset, available)
    end
  end

  def new(%{"available" => available} = attrs) when not is_map_key(attrs, "denom") do
    with {:ok, available} <- Amount.new(available) do
      build(attrs, nil, available)
    end
  end

  def new(attrs)
      when is_map(attrs) and not is_map_key(attrs, "denom") and
             not is_map_key(attrs, "available"),
      do: build(attrs, nil, nil)

  def new(_), do: {:error, :invalid_attrs}

  # --- Queries ---

  @spec get(String.t(), String.t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def get(vault, address, opts \\ []) do
    with {:ok, opts} <- Cache.pin(opts),
         {:ok, res} <- query(vault, address, opts) do
      new(res)
    end
  end

  @spec list(String.t(), Node.opts()) :: {:ok, [t()]} | {:error, term()}
  def list(vault, opts \\ []) do
    with {:ok, opts} <- Cache.pin(opts),
         {:ok, borrowers} <- query_borrowers(vault, opts) do
      Rujira.Enum.reduce_while_ok(borrowers, &new/1)
    end
  end

  @doc "A borrower's raw position on a vault, cached per `Rujira.Cache`."
  @spec query(String.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def query(vault, address), do: query(vault, address, [])

  @doc """
  As `query/2`, cached per `Rujira.Cache`; resolved at `opts[:height]` or the
  head.
  """
  @spec query(String.t(), String.t(), Node.opts()) :: {:ok, map()} | {:error, term()}
  def query(vault, address, opts) do
    with {:ok, opts} <- Cache.pin(opts) do
      Cache.fetch({__MODULE__, :query, [vault, address]}, [:per_block], opts, fn _height ->
        fetch(vault, address, opts)
      end)
    end
  end

  @doc "Every raw borrower position on a vault, paginated internally, cached per `Rujira.Cache`."
  @spec query_borrowers(String.t()) :: {:ok, [map()]} | {:error, term()}
  def query_borrowers(vault), do: query_borrowers(vault, [])

  @doc """
  As `query_borrowers/1`, cached per `Rujira.Cache`; resolved at `opts[:height]`
  or the head.
  """
  @spec query_borrowers(String.t(), Node.opts()) :: {:ok, [map()]} | {:error, term()}
  def query_borrowers(vault, opts) do
    with {:ok, opts} <- Cache.pin(opts) do
      Cache.fetch({__MODULE__, :query_borrowers, [vault]}, [:per_block], opts, fn _height ->
        query_borrowers_page(vault, nil, opts)
      end)
    end
  end

  # --- Private ---

  defp build(
         %{"addr" => addr, "limit" => limit, "current" => current, "shares" => shares},
         asset,
         available
       ) do
    with {:ok, limit} <- Amount.new(limit),
         {:ok, current} <- Amount.new(current),
         {:ok, shares} <- Math.to_decimal(shares) do
      {:ok,
       %__MODULE__{
         address: addr,
         asset: asset,
         limit: limit,
         current: current,
         shares: shares,
         available: available
       }}
    end
  end

  defp build(_, _, _), do: {:error, :invalid_attrs}

  defp fetch(vault, address, opts) do
    Contracts.query_state_smart(vault, %{borrower: %{addr: address}}, opts)
  end

  defp query_borrowers_page(vault, cursor, opts) do
    vault
    |> Contracts.query_state_smart_with_retry(
      %{borrowers: %{start_after: cursor, limit: @max_limit}},
      opts
    )
    |> Contracts.paginate("borrowers", @max_limit, fn borrowers ->
      query_borrowers_page(vault, borrowers |> List.last() |> Map.get("addr"), opts)
    end)
  end
end
