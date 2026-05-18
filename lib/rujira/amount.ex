defmodule Rujira.Amount do
  @moduledoc """
  Integer amounts normalized to 8 decimal places.

  All amounts in the Rujira protocol are represented as non-negative integers
  where `1.0 = 100_000_000` (1e8). This module provides a single entry point
  `new/1` that accepts any numeric input and normalizes it.

  ## Examples

      iex> Rujira.Amount.new(100)
      {:ok, 100}

      iex> Rujira.Amount.new("500")
      {:ok, 500}

      iex> Rujira.Amount.new("1000.75")
      {:ok, 1000}

      iex> Rujira.Amount.new(Decimal.new("1000"))
      {:ok, 1000}

      iex> Rujira.Amount.new("abc")
      {:error, :invalid_amount}
  """

  @decimals 8
  @precision trunc(:math.pow(10, @decimals))

  @type t :: non_neg_integer()

  @doc "Returns the number of decimal places (8)."
  @spec decimals() :: non_neg_integer()
  def decimals, do: @decimals

  @doc "Returns the precision multiplier (100_000_000)."
  @spec precision() :: non_neg_integer()
  def precision, do: @precision

  @doc """
  Creates an amount from any numeric input.

  Accepts nil, integers, binary strings, Decimals, and floats.
  Decimals and floats are floored to the nearest integer.
  `nil` passes through as `{:ok, nil}`.

  Returns `{:ok, amount}`, `{:ok, nil}`, or `{:error, :invalid_amount}`.
  """
  @spec new(nil | integer() | String.t() | Decimal.t() | float()) ::
          {:ok, t() | nil} | {:error, :invalid_amount}
  def new(nil), do: {:ok, nil}
  def new(value) when is_integer(value) and value >= 0, do: {:ok, value}

  def new(value) when is_binary(value) do
    case Decimal.parse(value) do
      {decimal, ""} -> new(decimal)
      _ -> {:error, :invalid_amount}
    end
  end

  def new(%Decimal{} = value) do
    result =
      value
      |> Decimal.round(0, :floor)
      |> Decimal.to_integer()

    if result >= 0, do: {:ok, result}, else: {:error, :invalid_amount}
  end

  def new(value) when is_float(value) and value >= 0 do
    value
    |> Decimal.from_float()
    |> new()
  end

  def new(_), do: {:error, :invalid_amount}

  @doc """
  Normalizes an amount from `from_decimals` precision to 8 decimal places.

  ## Examples

      iex> Rujira.Amount.normalize(1_000_000, 6)
      {:ok, 100_000_000}

      iex> Rujira.Amount.normalize(1_000_000_000_000_000_000, 18)
      {:ok, 100_000_000}
  """
  @spec normalize(integer(), non_neg_integer()) :: {:ok, t()} | {:error, :invalid_amount}
  def normalize(amount, from_decimals) when is_integer(amount) and is_integer(from_decimals) do
    result =
      amount
      |> Decimal.new()
      |> Decimal.mult(Decimal.new(10 ** @decimals))
      |> Decimal.div(Decimal.new(10 ** from_decimals))
      |> Decimal.round(0, :floor)
      |> Decimal.to_integer()

    if result >= 0, do: {:ok, result}, else: {:error, :invalid_amount}
  end

  def normalize(_, _), do: {:error, :invalid_amount}

  @doc """
  Converts an 8-decimal integer amount to a `Decimal`.

  ## Examples

      iex> Rujira.Amount.to_decimal(100_000_000)
      Decimal.new("1.00000000")
  """
  @spec to_decimal(t()) :: Decimal.t()
  def to_decimal(amount) when is_integer(amount) do
    amount
    |> Decimal.new()
    |> Decimal.div(Decimal.new(@precision))
  end

  @doc """
  Formats an 8-decimal integer amount as a human-readable string.

  ## Examples

      iex> Rujira.Amount.format(100_000_000)
      "1.00000000"

      iex> Rujira.Amount.format(50_000)
      "0.00050000"
  """
  @spec format(t()) :: String.t()
  def format(amount) when is_integer(amount) do
    amount
    |> to_decimal()
    |> Decimal.to_string(:normal)
  end
end
