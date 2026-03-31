defmodule Rujira.Thorchain.Oracle do
  @moduledoc """
  Oracle struct for Thorchain Enshrined Oracle data.
  """
  defstruct [:id, :asset, :symbol, :price]

  @type t :: %__MODULE__{
          id: String.t(),
          asset: Rujira.Assets.Asset.t() | nil,
          symbol: String.t(),
          price: Decimal.t() | nil
        }
end
