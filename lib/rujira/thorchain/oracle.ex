defmodule Rujira.Thorchain.Oracle do
  @moduledoc """
  Oracle struct for Thorchain Enshrined Oracle data.
  """
  defstruct id: nil, asset: nil, ticker: nil, price: nil

  @type t :: %__MODULE__{
          id: String.t(),
          asset: Rujira.Assets.Asset.t() | nil,
          ticker: String.t(),
          price: Decimal.t() | nil
        }
end
