defmodule Rujira.Fin.Events.TradeRange do
  @moduledoc """
  A single range touched by a concentrated-liquidity trade.

  The contract joins one entry per range into the trade event's `ranges`
  attribute with commas. Each entry is colon-separated. The leading segment is
  the range id, which itself embeds the price bounds as `idx:low-high`, so a
  full entry has the shape:

    * base-side fill:  `idx:low-high:base:quote:deduct:add::fee`  (7th slot empty)
    * quote-side fill: `idx:low-high:base:quote:deduct:add:fee:`  (8th slot empty)

  All amounts and bounds are the range's internal full-precision `Decimal`
  values, not 8-decimal token integers.
  """

  alias Rujira.Math

  defstruct idx: 0,
            low: Decimal.new(0),
            high: Decimal.new(0),
            side: :base,
            base: Decimal.new(0),
            quote: Decimal.new(0),
            deduct: Decimal.new(0),
            add: Decimal.new(0),
            fee: Decimal.new(0)

  @type t :: %__MODULE__{
          idx: non_neg_integer(),
          low: Decimal.t(),
          high: Decimal.t(),
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
    with [idx, bounds, base, quote, deduct, add, f7, f8] <- String.split(entry, ":"),
         [low, high] <- String.split(bounds, "-"),
         {:ok, {side, fee}} <- fee_slot(f7, f8),
         {:ok, idx} <- Math.to_integer(idx),
         {:ok, low} <- Math.to_decimal(low),
         {:ok, high} <- Math.to_decimal(high),
         {:ok, base} <- Math.to_decimal(base),
         {:ok, quote} <- Math.to_decimal(quote),
         {:ok, deduct} <- Math.to_decimal(deduct),
         {:ok, add} <- Math.to_decimal(add),
         {:ok, fee} <- Math.to_decimal(fee) do
      {:ok,
       %__MODULE__{
         idx: idx,
         low: low,
         high: high,
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
