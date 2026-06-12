defmodule Rujira.Thorchain.Events.PendingLiquidity do
  @moduledoc "A THORChain pending liquidity event (`pending_liquidity`)."

  alias Rujira.Amount

  defstruct pool: nil,
            type: nil,
            rune_address: nil,
            asset_address: nil,
            rune_amount: 0,
            asset_amount: 0

  @type t :: %__MODULE__{
          pool: String.t(),
          type: String.t(),
          rune_address: String.t(),
          asset_address: String.t(),
          rune_amount: Amount.t(),
          asset_amount: Amount.t()
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{
        "pool" => pool,
        "type" => type,
        "rune_address" => rune_address,
        "asset_address" => asset_address,
        "rune_amount" => rune_amount,
        "asset_amount" => asset_amount
      }) do
    with {:ok, rune_amount} <- Amount.new(rune_amount),
         {:ok, asset_amount} <- Amount.new(asset_amount) do
      {:ok,
       %__MODULE__{
         pool: pool,
         type: type,
         rune_address: rune_address,
         asset_address: asset_address,
         rune_amount: rune_amount,
         asset_amount: asset_amount
       }}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
