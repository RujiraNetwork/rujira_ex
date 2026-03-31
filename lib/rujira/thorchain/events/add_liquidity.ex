defmodule Rujira.Thorchain.Events.AddLiquidity do
  @moduledoc "A THORChain add liquidity event."

  defstruct [:pool, :rune_address, :asset_address]

  @type t :: %__MODULE__{
          pool: String.t(),
          rune_address: String.t() | nil,
          asset_address: String.t() | nil
        }

  @spec new(map()) :: {:ok, t()}
  def new(%{"pool" => pool} = attrs) do
    {:ok,
     %__MODULE__{
       pool: pool,
       rune_address: Map.get(attrs, "rune_address"),
       asset_address: Map.get(attrs, "asset_address")
     }}
  end
end
