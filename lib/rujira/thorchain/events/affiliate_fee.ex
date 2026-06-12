defmodule Rujira.Thorchain.Events.AffiliateFee do
  @moduledoc "A THORChain affiliate fee event (`affiliate_fee`)."

  alias Rujira.Amount
  alias Rujira.Math

  defstruct tx_id: nil,
            memo: nil,
            thorname: nil,
            rune_address: nil,
            asset: nil,
            gross_amount: 0,
            fee_bps: 0,
            fee_amount: 0

  @type t :: %__MODULE__{
          tx_id: String.t(),
          memo: String.t(),
          thorname: String.t(),
          rune_address: String.t(),
          asset: String.t(),
          gross_amount: Amount.t(),
          fee_bps: integer(),
          fee_amount: Amount.t()
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{
        "tx_id" => tx_id,
        "memo" => memo,
        "thorname" => thorname,
        "rune_address" => rune_address,
        "asset" => asset,
        "gross_amount" => gross_amount,
        "fee_bps" => fee_bps,
        "fee_amount" => fee_amount
      }) do
    with {:ok, gross_amount} <- Amount.new(gross_amount),
         {:ok, fee_bps} <- Math.to_integer(fee_bps),
         {:ok, fee_amount} <- Amount.new(fee_amount) do
      {:ok,
       %__MODULE__{
         tx_id: tx_id,
         memo: memo,
         thorname: thorname,
         rune_address: rune_address,
         asset: asset,
         gross_amount: gross_amount,
         fee_bps: fee_bps,
         fee_amount: fee_amount
       }}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
