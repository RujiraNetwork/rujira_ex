defmodule Rujira.Fin.Range.Dynamic do
  @moduledoc """
  State of a dynamic concentrated liquidity range.

  Rather than fixed bounds, a dynamic range quotes around an average entry price
  (`aep`), placing bids and asks at the depths set by its `params`. Realized
  profit is split between compounded principal and a segregated claimable
  balance. Carried under `range:` on `Rujira.Fin.Range`.
  """

  alias Rujira.Amount
  alias Rujira.Fin.Range.Dynamic.Params
  alias Rujira.Math

  # --- Struct ---

  defstruct params: %Params{},
            base: 0,
            quote: 0,
            claimable_base: 0,
            claimable_quote: 0,
            cost_basis: Decimal.new(0),
            aep: Decimal.new(0)

  @type t :: %__MODULE__{
          params: Params.t(),
          base: Amount.t(),
          quote: Amount.t(),
          claimable_base: Amount.t(),
          claimable_quote: Amount.t(),
          cost_basis: Decimal.t(),
          aep: Decimal.t()
        }

  # --- Construction ---

  @doc """
  Parses the dynamic arm of a range query response.

  The contract flattens `params` into the response, so the strategy parameters
  arrive alongside the balances rather than nested.
  """
  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(
        %{
          "base" => base,
          "quote" => quote,
          "claimable_base" => claimable_base,
          "claimable_quote" => claimable_quote,
          "cost_basis" => cost_basis,
          "aep" => aep
        } = attrs
      ) do
    with {:ok, params} <- Params.new(attrs),
         {:ok, base} <- Amount.new(base),
         {:ok, quote_} <- Amount.new(quote),
         {:ok, claimable_base} <- Amount.new(claimable_base),
         {:ok, claimable_quote} <- Amount.new(claimable_quote),
         {:ok, cost_basis} <- Math.to_decimal(cost_basis),
         {:ok, aep} <- Math.to_decimal(aep) do
      {:ok,
       %__MODULE__{
         params: params,
         base: base,
         quote: quote_,
         claimable_base: claimable_base,
         claimable_quote: claimable_quote,
         cost_basis: cost_basis,
         aep: aep
       }}
    end
  end

  def new(_), do: {:error, :invalid_attrs}

  # --- Calculations ---

  @doc "Total base and quote held by the range, including segregated profit."
  @spec totals(t()) :: {Amount.t(), Amount.t()}
  def totals(%__MODULE__{} = range),
    do: {range.base + range.claimable_base, range.quote + range.claimable_quote}
end
