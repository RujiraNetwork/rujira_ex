defmodule Rujira.Math do
  @moduledoc """
  Math utilities for Rujira financial calculations
  """

  # Decimal 3 defaults to decimal128 limits, rejecting inputs over 34 significant
  # digits. That is narrower than the chain: a CosmWasm `Decimal` serialises up to
  # 39 digits and a `Decimal256` up to 96 (78 integer + 18 fractional), so the
  # default would reject legitimate on-chain values. Widening the digit count is
  # safe because the CVE-2026-32686 vector is exponent amplification (`1e1000000`),
  # which the still-bounded `:max_exponent` default rejects — a 96-character
  # literal carries no amplification.
  @max_digits 96

  @doc """
  Significant-digit ceiling used when parsing chain-sourced decimal strings.

  Wide enough for every CosmWasm fixed-point type, narrow enough to stay finite.
  """
  @spec max_digits() :: pos_integer()
  def max_digits, do: @max_digits

  @doc """
  Parses any value to an integer. `nil` passes through.

  `nil` and `""` pass through as `{:ok, nil}`.

  Returns `{:ok, integer}`, `{:ok, nil}`, or `{:error, :invalid_integer}`.
  """
  @spec to_integer(nil | integer() | String.t()) ::
          {:ok, integer() | nil} | {:error, :invalid_integer}
  def to_integer(nil), do: {:ok, nil}
  def to_integer(""), do: {:ok, nil}
  def to_integer(value) when is_integer(value), do: {:ok, value}

  def to_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {n, ""} -> {:ok, n}
      _ -> {:error, :invalid_integer}
    end
  end

  def to_integer(_), do: {:error, :invalid_integer}

  @doc """
  Parses any value to a Decimal. `nil` passes through.

  `nil` and `""` pass through as `{:ok, nil}`.

  Returns `{:ok, Decimal.t}`, `{:ok, nil}`, or `{:error, :invalid_decimal}`.
  """
  @spec to_decimal(nil | integer() | float() | String.t() | Decimal.t()) ::
          {:ok, Decimal.t() | nil} | {:error, :invalid_decimal}
  def to_decimal(nil), do: {:ok, nil}
  def to_decimal(""), do: {:ok, nil}
  def to_decimal(%Decimal{} = value), do: {:ok, value}
  def to_decimal(value) when is_integer(value), do: {:ok, Decimal.new(value)}
  def to_decimal(value) when is_float(value), do: {:ok, Decimal.from_float(value)}

  def to_decimal(value) when is_binary(value) do
    case Decimal.parse(value, max_digits: @max_digits) do
      {d, ""} -> {:ok, d}
      _ -> {:error, :invalid_decimal}
    end
  end

  def to_decimal(_), do: {:error, :invalid_decimal}

  @doc """
  Multiply two numbers and round down to integer
  """
  @spec mul_floor(number() | Decimal.t(), number() | Decimal.t()) :: integer()
  def mul_floor(a, b) do
    Decimal.new(a)
    |> Decimal.mult(Decimal.new(b))
    |> Decimal.round(0, :floor)
    |> Decimal.to_integer()
  end

  @doc """
  Divide two numbers and round down to integer
  """
  @spec div_floor(number() | Decimal.t(), number() | Decimal.t()) :: integer()
  def div_floor(a, b) do
    Decimal.new(a)
    |> Decimal.div(Decimal.new(b))
    |> Decimal.round(0, :floor)
    |> Decimal.to_integer()
  end

  @doc """
  Safe division that returns 0 if divisor is zero
  """
  @spec safe_div(number() | Decimal.t(), number() | Decimal.t()) :: Decimal.t()
  def safe_div(a, b) do
    b_decimal = Decimal.new(b)

    if Decimal.eq?(b_decimal, Decimal.new(0)) do
      Decimal.new(0)
    else
      Decimal.div(Decimal.new(a), b_decimal)
    end
  end

  @doc """
  Convert number from one decimal precision to another
  """
  @spec normalize(number() | float() | Decimal.t(), integer(), integer()) :: Decimal.t()
  def normalize(a, from \\ 0, to \\ Rujira.Amount.decimals())

  def normalize(a, from, to) when is_float(a),
    do: do_normalize(Decimal.from_float(a), from, to)

  def normalize(a, from, to),
    do: do_normalize(Decimal.new(a), from, to)

  defp do_normalize(a, from, to) when to >= from do
    Decimal.mult(a, Decimal.new(10 ** (to - from)))
  end

  defp do_normalize(a, from, to) do
    Decimal.div(a, Decimal.new(10 ** (from - to)))
  end

  @doc """
  Round down to integer using floor
  """
  @spec floor(number() | Decimal.t()) :: integer()
  def floor(a) do
    Decimal.new(a)
    |> Decimal.round(0, :floor)
    |> Decimal.to_integer()
  end

  @doc """
  Average of two numbers
  """
  @spec avg(number() | Decimal.t(), number() | Decimal.t()) :: Decimal.t()
  def avg(a, b) do
    Decimal.div(Decimal.add(Decimal.new(a), Decimal.new(b)), 2)
  end
end
