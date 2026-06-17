defmodule Rujira.Ghost.Vault.Status do
  @moduledoc "Live interest and utilization state of a Ghost vault."

  alias Rujira.Amount
  alias Rujira.Math

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

  defstruct last_updated: nil,
            utilization_ratio: Decimal.new(0),
            debt_rate: Decimal.new(0),
            lend_rate: Decimal.new(0),
            debt_pool: nil,
            deposit_pool: nil

  @type t :: %__MODULE__{
          last_updated: DateTime.t() | nil,
          utilization_ratio: Decimal.t(),
          debt_rate: Decimal.t(),
          lend_rate: Decimal.t(),
          debt_pool: DebtPool.t() | nil,
          deposit_pool: DepositPool.t() | nil
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{
        "last_updated" => last_updated,
        "utilization_ratio" => utilization_ratio,
        "debt_rate" => debt_rate,
        "lend_rate" => lend_rate,
        "debt_pool" => debt_pool,
        "deposit_pool" => deposit_pool
      }) do
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
         deposit_pool: deposit_pool
       }}
    end
  end

  def new(_), do: {:error, :invalid_attrs}

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
