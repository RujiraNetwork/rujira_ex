defmodule Rujira.Fin.Events.ArbLot do
  @moduledoc """
  An arbitrage lot handed to an arb market maker (`wasm-rujira-fin/arb_lot`).

  FIN sends `offer` to `provider` and expects at least `ask` back through
  `SettleArb`. The three `*_value` fields are the lot's surplus valued in
  quote units at `valuation`, the reference price used for the lot. They are
  `Decimal256` on the wire and floored to `Rujira.Amount`.

  `arb_objective` is the surplus the contract maximised when it picked the lot:
  `:fin_surplus` or `:total_rujira_surplus`. Any other value fails the parse
  with `{:error, :invalid_arb_objective}`.
  """

  alias Rujira.Amount
  alias Rujira.Coin
  alias Rujira.Math

  defstruct provider: nil,
            offer: nil,
            ask: nil,
            protocol_range_fee_value: 0,
            fin_surplus_value: 0,
            total_surplus_value: 0,
            arb_objective: nil,
            valuation: Decimal.new(0)

  @type arb_objective :: :fin_surplus | :total_rujira_surplus

  @type t :: %__MODULE__{
          provider: String.t() | nil,
          offer: Coin.t() | nil,
          ask: Coin.t() | nil,
          protocol_range_fee_value: Amount.t(),
          fin_surplus_value: Amount.t(),
          total_surplus_value: Amount.t(),
          arb_objective: arb_objective() | nil,
          valuation: Decimal.t()
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{
        "provider" => provider,
        "offer" => offer,
        "ask" => ask,
        "protocol_range_fee_value" => protocol_range_fee_value,
        "fin_surplus_value" => fin_surplus_value,
        "total_surplus_value" => total_surplus_value,
        "arb_objective" => arb_objective,
        "valuation" => valuation
      }) do
    with {:ok, offer} <- coin(offer),
         {:ok, ask} <- coin(ask),
         {:ok, protocol_range_fee_value} <- amount(protocol_range_fee_value),
         {:ok, fin_surplus_value} <- amount(fin_surplus_value),
         {:ok, total_surplus_value} <- amount(total_surplus_value),
         {:ok, arb_objective} <- arb_objective(arb_objective),
         {:ok, valuation} <- decimal(valuation) do
      {:ok,
       %__MODULE__{
         provider: provider,
         offer: offer,
         ask: ask,
         protocol_range_fee_value: protocol_range_fee_value,
         fin_surplus_value: fin_surplus_value,
         total_surplus_value: total_surplus_value,
         arb_objective: arb_objective,
         valuation: valuation
       }}
    end
  end

  def new(_), do: {:error, :invalid_attrs}

  # --- Private ---

  defp coin(value) do
    case Coin.parse(value) do
      {:ok, [coin]} -> {:ok, coin}
      {:ok, _} -> {:error, :invalid_coin_format}
      {:error, _} = err -> err
    end
  end

  defp amount(value) do
    case Amount.new(value) do
      {:ok, nil} -> {:error, :invalid_amount}
      other -> other
    end
  end

  defp decimal(value) do
    case Math.to_decimal(value) do
      {:ok, nil} -> {:error, :invalid_decimal}
      other -> other
    end
  end

  defp arb_objective("fin_surplus"), do: {:ok, :fin_surplus}
  defp arb_objective("total_rujira_surplus"), do: {:ok, :total_rujira_surplus}
  defp arb_objective(_), do: {:error, :invalid_arb_objective}
end
