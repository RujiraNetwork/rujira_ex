defmodule Rujira.Thorchain.Events.PendingLiquidity do
  @moduledoc "A THORChain pending liquidity event."

  defstruct pool: nil, rune_address: nil, asset_address: nil

  @type t :: %__MODULE__{
          pool: String.t(),
          rune_address: String.t() | nil,
          asset_address: String.t() | nil
        }

  @spec new(map()) :: {:ok, t()} | {:error, :invalid_attrs}
  def new(%{"pool" => pool} = attrs) do
    {:ok,
     %__MODULE__{
       pool: pool,
       rune_address: Map.get(attrs, "rune_address"),
       asset_address: Map.get(attrs, "asset_address")
     }}
  end

  def new(_), do: {:error, :invalid_attrs}
end
