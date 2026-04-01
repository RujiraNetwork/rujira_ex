defmodule Rujira.Assets.Asset do
  @moduledoc """
  Defines the Asset struct for representing blockchain assets.
  """
  defstruct id: nil, type: nil, chain: nil, symbol: nil, ticker: nil, metadata: nil

  alias Rujira.Assets.Metadata

  @type t :: %__MODULE__{
          id: String.t() | nil,
          type: :native | :secured | :layer_1 | :synth | :trade | nil,
          chain: String.t() | nil,
          symbol: String.t() | nil,
          ticker: String.t() | nil,
          metadata: Metadata.t() | nil
        }
end
