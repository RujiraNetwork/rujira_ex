defmodule Rujira.Ghost.Vault.Status do
  @moduledoc """
  Live interest and utilization state of a Ghost vault.

  Struct, construction, and queries. Use `Rujira.Ghost` as the public API.

  Parses every shape the vault's `status` query has served. A vault read at
  an older height serves the shape of the code it ran then. Fields a shape
  does not carry are `nil`:

  | Shape | Contract          | Upstream             | `interest` | `debt_pool.shares` on the wire |
  | ----- | ----------------- | -------------------- | ---------- | ------------------------------ |
  | S0    | v0.0.1 to v0.1.2  | `787e63b`..`fbf80aa` | set        | `Uint128`                      |
  | S1    | v1.0.0 to v1.0.8  | `355aafa`..`9264370` | `nil`      | `Uint128`                      |
  | S2    | v1.1.0 and later  | `3ee2d68`+           | `nil`      | `Decimal`                      |

  From v1.0.0 the interest curve moved to the vault's `config` (see
  `Rujira.Ghost.Vault`); `interest` here is only the v0.x status's own copy.
  `debt_pool.shares` is a `Decimal` on every shape, since an integer string
  parses as one.
  """

  alias Rujira.Amount
  alias Rujira.Cache
  alias Rujira.Contracts
  alias Rujira.Ghost.Vault
  alias Rujira.Ghost.Vault.Interest
  alias Rujira.Math
  alias Rujira.Node

  defmodule DebtPool do
    @moduledoc "Share pool that accounts for accrued debt interest (`shares` is a `Decimal`)."
    defstruct size: 0, shares: Decimal.new(0), ratio: Decimal.new(0)

    @type t :: %__MODULE__{size: Rujira.Amount.t(), shares: Decimal.t(), ratio: Decimal.t()}
  end

  defmodule DepositPool do
    @moduledoc "Share pool that allocates collected debt interest to lenders (`shares` is a `Uint128`)."
    defstruct size: 0, shares: 0, ratio: Decimal.new(0)

    @type t :: %__MODULE__{size: Rujira.Amount.t(), shares: Rujira.Amount.t(), ratio: Decimal.t()}
  end

  # --- Struct ---

  defstruct last_updated: nil,
            utilization_ratio: Decimal.new(0),
            debt_rate: Decimal.new(0),
            lend_rate: Decimal.new(0),
            debt_pool: nil,
            deposit_pool: nil,
            interest: nil

  @type t :: %__MODULE__{
          last_updated: DateTime.t() | nil,
          utilization_ratio: Decimal.t(),
          debt_rate: Decimal.t(),
          lend_rate: Decimal.t(),
          debt_pool: DebtPool.t() | nil,
          deposit_pool: DepositPool.t() | nil,
          interest: Interest.t() | nil
        }

  # --- Construction ---

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"interest" => interest} = attrs) do
    with {:ok, interest} <- Interest.new(interest) do
      build(attrs, interest)
    end
  end

  def new(attrs) when is_map(attrs), do: build(attrs, nil)

  def new(_), do: {:error, :invalid_attrs}

  # --- Queries ---

  @doc "Loads the vault's live status into its `status` field, at `opts[:height]` when given."
  @spec load(Vault.t(), Node.opts()) :: {:ok, Vault.t()} | {:error, term()}
  def load(%Vault{address: address} = vault, opts \\ []) do
    with {:ok, opts} <- Cache.pin(opts),
         {:ok, res} <- query(address, opts),
         {:ok, status} <- new(res) do
      {:ok, %{vault | status: status}}
    end
  end

  @doc "A vault's live status, cached per `Rujira.Cache`."
  @spec query(String.t()) :: {:ok, map()} | {:error, term()}
  def query(address), do: query(address, [])

  @doc """
  As `query/1`, cached per `Rujira.Cache`; resolved at `opts[:height]` or the
  head.
  """
  @spec query(String.t(), Node.opts()) :: {:ok, map()} | {:error, term()}
  def query(address, opts) do
    with {:ok, opts} <- Cache.pin(opts) do
      Cache.fetch({__MODULE__, :query, [address]}, [:per_block], opts, fn _height ->
        fetch(address, opts)
      end)
    end
  end

  # --- Private ---

  defp build(
         %{
           "last_updated" => last_updated,
           "utilization_ratio" => utilization_ratio,
           "debt_rate" => debt_rate,
           "lend_rate" => lend_rate,
           "debt_pool" => debt_pool,
           "deposit_pool" => deposit_pool
         },
         interest
       ) do
    with {:ok, last_updated} <- Math.to_integer(last_updated),
         {:ok, last_updated} <- DateTime.from_unix(last_updated, :nanosecond),
         {:ok, utilization_ratio} <- Math.to_decimal(utilization_ratio),
         {:ok, debt_rate} <- Math.to_decimal(debt_rate),
         {:ok, lend_rate} <- Math.to_decimal(lend_rate),
         {:ok, debt_pool} <- debt_pool(debt_pool),
         {:ok, deposit_pool} <- deposit_pool(deposit_pool) do
      {:ok,
       %__MODULE__{
         last_updated: last_updated,
         utilization_ratio: utilization_ratio,
         debt_rate: debt_rate,
         lend_rate: lend_rate,
         debt_pool: debt_pool,
         deposit_pool: deposit_pool,
         interest: interest
       }}
    end
  end

  defp build(_, _), do: {:error, :invalid_attrs}

  defp fetch(address, opts) do
    Contracts.query_state_smart(address, %{status: %{}}, opts)
  end

  defp debt_pool(%{"size" => size, "shares" => shares, "ratio" => ratio}) do
    with {:ok, size} <- Amount.new(size),
         {:ok, shares} <- Math.to_decimal(shares),
         {:ok, ratio} <- Math.to_decimal(ratio) do
      {:ok, %DebtPool{size: size, shares: shares, ratio: ratio}}
    end
  end

  defp debt_pool(_), do: {:error, :invalid_attrs}

  defp deposit_pool(%{"size" => size, "shares" => shares, "ratio" => ratio}) do
    with {:ok, size} <- Amount.new(size),
         {:ok, shares} <- Amount.new(shares),
         {:ok, ratio} <- Math.to_decimal(ratio) do
      {:ok, %DepositPool{size: size, shares: shares, ratio: ratio}}
    end
  end

  defp deposit_pool(_), do: {:error, :invalid_attrs}
end
