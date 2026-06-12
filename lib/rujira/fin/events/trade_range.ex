defmodule Rujira.Fin.Events.TradeRange do
  @moduledoc """
  A single range touched by a concentrated-liquidity trade.

  The contract joins one entry per range into the trade event's `ranges`
  attribute with commas. Each entry is colon-separated and the fee occupies a
  different slot depending on the fill side:

    * base-side fill:  `idx:base:quote:deduct:add::fee`  (6th slot empty)
    * quote-side fill: `idx:base:quote:deduct:add:fee:`  (7th slot empty)

  All amounts are the range's internal full-precision `Decimal` values, not
  8-decimal token integers.
  """

  alias Rujira.Math

  defstruct idx: 0,
            side: :base,
            base: Decimal.new(0),
            quote: Decimal.new(0),
            deduct: Decimal.new(0),
            add: Decimal.new(0),
            fee: Decimal.new(0)

  @type t :: %__MODULE__{
          idx: non_neg_integer(),
          side: :base | :quote,
          base: Decimal.t(),
          quote: Decimal.t(),
          deduct: Decimal.t(),
          add: Decimal.t(),
          fee: Decimal.t()
        }

  @spec parse_list(nil | String.t()) :: {:ok, [t()] | nil} | {:error, term()}
  def parse_list(nil), do: {:ok, nil}

  def parse_list(value) when is_binary(value) do
    value
    |> String.split(",", trim: true)
    |> Enum.reduce_while({:ok, []}, fn entry, {:ok, acc} ->
      case parse(entry) do
        {:ok, range} -> {:cont, {:ok, [range | acc]}}
        {:error, _} = err -> {:halt, err}
      end
    end)
    |> case do
      {:ok, ranges} -> {:ok, Enum.reverse(ranges)}
      err -> err
    end
  end

  def parse_list(_), do: {:error, :invalid_ranges}

  @spec parse(String.t()) :: {:ok, t()} | {:error, term()}
  def parse(entry) when is_binary(entry) do
    with [idx, base, quote, deduct, add, f6, f7] <- String.split(entry, ":"),
         {:ok, {side, fee}} <- fee_slot(f6, f7),
         {:ok, idx} <- Math.to_integer(idx),
         {:ok, base} <- Math.to_decimal(base),
         {:ok, quote} <- Math.to_decimal(quote),
         {:ok, deduct} <- Math.to_decimal(deduct),
         {:ok, add} <- Math.to_decimal(add),
         {:ok, fee} <- Math.to_decimal(fee) do
      {:ok,
       %__MODULE__{
         idx: idx,
         side: side,
         base: base,
         quote: quote,
         deduct: deduct,
         add: add,
         fee: fee
       }}
    else
      {:error, _} = err -> err
      _ -> {:error, :invalid_range}
    end
  end

  def parse(_), do: {:error, :invalid_range}

  defp fee_slot("", fee), do: {:ok, {:base, fee}}
  defp fee_slot(fee, ""), do: {:ok, {:quote, fee}}
  defp fee_slot(_, _), do: {:error, :invalid_range}
end
