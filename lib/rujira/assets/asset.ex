defmodule Rujira.Assets.Asset do
  @moduledoc """
  Defines the Asset struct for representing blockchain assets.
  """
  defstruct [:id, :type, :chain, :symbol, :ticker, :metadata]

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
