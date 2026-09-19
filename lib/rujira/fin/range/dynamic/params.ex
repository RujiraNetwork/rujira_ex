defmodule Rujira.Fin.Range.Dynamic.Params do
  @moduledoc """
  Strategy parameters of a dynamic range.

  The contract carries these as a single `DynamicRangeParams` struct, flattened
  into both the `range.create` event attributes and the range query response, so
  the same struct serves the event and query layers here.

  Numeric params always arrive as strings. `reanchor_aep_on_sellout` arrives as
  the string `"true"`/`"false"` on events and as a JSON boolean on queries.
  """

  alias Rujira.Math

  defstruct min_profit: Decimal.new(0),
            claimable_share: Decimal.new(0),
            bid_depth: Decimal.new(0),
            ask_depth: Decimal.new(0),
            skew: Decimal.new(0),
            reanchor_aep_on_sellout: false

  @type t :: %__MODULE__{
          min_profit: Decimal.t(),
          claimable_share: Decimal.t(),
          bid_depth: Decimal.t(),
          ask_depth: Decimal.t(),
          skew: Decimal.t(),
          reanchor_aep_on_sellout: boolean()
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{
        "min_profit" => min_profit,
        "claimable_share" => claimable_share,
        "bid_depth" => bid_depth,
        "ask_depth" => ask_depth,
        "skew" => skew,
        "reanchor_aep_on_sellout" => reanchor
      }) do
    with {:ok, min_profit} <- Math.to_decimal(min_profit),
         {:ok, claimable_share} <- Math.to_decimal(claimable_share),
         {:ok, bid_depth} <- Math.to_decimal(bid_depth),
         {:ok, ask_depth} <- Math.to_decimal(ask_depth),
         {:ok, skew} <- Math.to_decimal(skew),
         {:ok, reanchor} <- to_boolean(reanchor) do
      {:ok,
       %__MODULE__{
         min_profit: min_profit,
         claimable_share: claimable_share,
         bid_depth: bid_depth,
         ask_depth: ask_depth,
         skew: skew,
         reanchor_aep_on_sellout: reanchor
       }}
    end
  end

  def new(_), do: {:error, :invalid_attrs}

  defp to_boolean(value) when is_boolean(value), do: {:ok, value}
  defp to_boolean("true"), do: {:ok, true}
  defp to_boolean("false"), do: {:ok, false}
  defp to_boolean(_), do: {:error, :invalid_attrs}
end
