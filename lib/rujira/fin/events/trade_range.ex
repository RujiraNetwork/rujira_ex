defmodule Rujira.Fin.Events.TradeRange do
  @moduledoc """
  A single range touched by a concentrated-liquidity trade.

  The contract joins one entry per range into the trade event's `ranges`
  attribute with commas. Each entry is colon-separated, and its shape depends on
  which range implementation was filled. Fixed and dynamic fills are emitted as
  separate trade events, so in practice a single `ranges` attribute is
  homogeneous, but entries are dispatched individually regardless.

  A **fixed** entry leads with the range id, which itself embeds the price bounds
  as `idx:low-high`, so a full entry has the shape:

    * base-side fill:  `idx:low-high:base:quote:deduct:add::fee`  (7th slot empty)
    * quote-side fill: `idx:low-high:base:quote:deduct:add:fee:`  (8th slot empty)

  A **dynamic** entry leads with the literal `dynamic:`, names its side
  explicitly, and reports the full profit attribution of the fill:

      dynamic:idx:side:pre_aep:aep:oracle:effective_price:gross:fee:denom:
      deduct:add:profit:claimable:compounded:base:quote:claimable_base:
      claimable_quote:cost_basis

  All amounts and bounds are the range's internal full-precision `Decimal`
  values, not 8-decimal token integers.
  """

  alias Rujira.Math

  defmodule Fixed do
    @moduledoc "A fill against a fixed-bounds range, with the bounds it was quoted at."

    defstruct low: Decimal.new(0),
              high: Decimal.new(0),
              base: Decimal.new(0),
              quote: Decimal.new(0),
              deduct: Decimal.new(0),
              add: Decimal.new(0),
              fee: Decimal.new(0)

    @type t :: %__MODULE__{
            low: Decimal.t(),
            high: Decimal.t(),
            base: Decimal.t(),
            quote: Decimal.t(),
            deduct: Decimal.t(),
            add: Decimal.t(),
            fee: Decimal.t()
          }
  end

  defmodule Dynamic do
    @moduledoc """
    A fill against a dynamic range.

    `pre_aep` and `aep` bracket the fill — the average entry price before and
    after it. `profit` is realized against `pre_aep` and splits into `claimable`
    (segregated) and `compounded` (returned to principal). `denom` is the denom
    bid into the range.
    """

    defstruct pre_aep: Decimal.new(0),
              aep: Decimal.new(0),
              oracle: Decimal.new(0),
              effective_price: Decimal.new(0),
              gross: Decimal.new(0),
              fee: Decimal.new(0),
              denom: nil,
              deduct: Decimal.new(0),
              add: Decimal.new(0),
              profit: Decimal.new(0),
              claimable: Decimal.new(0),
              compounded: Decimal.new(0),
              base: Decimal.new(0),
              quote: Decimal.new(0),
              claimable_base: Decimal.new(0),
              claimable_quote: Decimal.new(0),
              cost_basis: Decimal.new(0)

    @type t :: %__MODULE__{
            pre_aep: Decimal.t(),
            aep: Decimal.t(),
            oracle: Decimal.t(),
            effective_price: Decimal.t(),
            gross: Decimal.t(),
            fee: Decimal.t(),
            denom: String.t() | nil,
            deduct: Decimal.t(),
            add: Decimal.t(),
            profit: Decimal.t(),
            claimable: Decimal.t(),
            compounded: Decimal.t(),
            base: Decimal.t(),
            quote: Decimal.t(),
            claimable_base: Decimal.t(),
            claimable_quote: Decimal.t(),
            cost_basis: Decimal.t()
          }
  end

  defstruct idx: 0, side: :base, range: nil

  @type t :: %__MODULE__{
          idx: non_neg_integer(),
          side: :base | :quote,
          range: Fixed.t() | Dynamic.t() | nil
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
  def parse("dynamic:" <> rest), do: parse_dynamic(rest)

  def parse(entry) when is_binary(entry) do
    with [idx, bounds, base, quote, deduct, add, f7, f8] <- String.split(entry, ":"),
         [low, high] <- String.split(bounds, "-"),
         {:ok, {side, fee}} <- fee_slot(f7, f8),
         {:ok, idx} <- Math.to_integer(idx),
         {:ok, values} <-
           Rujira.Enum.reduce_while_ok(
             [low, high, base, quote, deduct, add, fee],
             &Math.to_decimal/1
           ) do
      {:ok, %__MODULE__{idx: idx, side: side, range: fixed(values)}}
    else
      {:error, _} = err -> err
      _ -> {:error, :invalid_range}
    end
  end

  def parse(_), do: {:error, :invalid_range}

  # --- Private ---

  defp parse_dynamic(entry) do
    with [
           idx,
           side,
           pre_aep,
           aep,
           oracle,
           effective_price,
           gross,
           fee,
           denom,
           deduct,
           add,
           profit,
           claimable,
           compounded,
           base,
           quote,
           claimable_base,
           claimable_quote,
           cost_basis
         ] <- String.split(entry, ":"),
         {:ok, side} <- side(side),
         {:ok, idx} <- Math.to_integer(idx),
         {:ok, values} <-
           Rujira.Enum.reduce_while_ok(
             [
               pre_aep,
               aep,
               oracle,
               effective_price,
               gross,
               fee,
               deduct,
               add,
               profit,
               claimable,
               compounded,
               base,
               quote,
               claimable_base,
               claimable_quote,
               cost_basis
             ],
             &Math.to_decimal/1
           ) do
      {:ok, %__MODULE__{idx: idx, side: side, range: dynamic(denom, values)}}
    else
      {:error, _} = err -> err
      _ -> {:error, :invalid_range}
    end
  end

  defp fixed([low, high, base, quote, deduct, add, fee]) do
    %Fixed{
      low: low,
      high: high,
      base: base,
      quote: quote,
      deduct: deduct,
      add: add,
      fee: fee
    }
  end

  defp dynamic(denom, [
         pre_aep,
         aep,
         oracle,
         effective_price,
         gross,
         fee,
         deduct,
         add,
         profit,
         claimable,
         compounded,
         base,
         quote,
         claimable_base,
         claimable_quote,
         cost_basis
       ]) do
    %Dynamic{
      pre_aep: pre_aep,
      aep: aep,
      oracle: oracle,
      effective_price: effective_price,
      gross: gross,
      fee: fee,
      denom: denom,
      deduct: deduct,
      add: add,
      profit: profit,
      claimable: claimable,
      compounded: compounded,
      base: base,
      quote: quote,
      claimable_base: claimable_base,
      claimable_quote: claimable_quote,
      cost_basis: cost_basis
    }
  end

  defp side("base"), do: {:ok, :base}
  defp side("quote"), do: {:ok, :quote}
  defp side(_), do: {:error, :invalid_range}

  defp fee_slot("", fee), do: {:ok, {:base, fee}}
  defp fee_slot(fee, ""), do: {:ok, {:quote, fee}}
  defp fee_slot(_, _), do: {:error, :invalid_range}
end
