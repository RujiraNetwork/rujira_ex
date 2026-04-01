defmodule Rujira.Assets.Asset do
  @moduledoc """
  Defines the Asset struct for representing blockchain assets.
  """
  defstruct id: nil, type: nil, chain: nil, symbol: nil, ticker: nil, metadata: nil

  alias Rujira.Assets.Metadata

  @type t :: %__MODULE__{
          id: String.t(),
          type: :native | :secured | :layer_1 | :synth | :trade,
          chain: String.t(),
          symbol: String.t(),
          ticker: String.t(),
          metadata: Metadata.t() | nil
        }
end
