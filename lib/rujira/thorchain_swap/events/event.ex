defmodule Rujira.ThorchainSwap.Events.Event do
  @moduledoc "Protocol-level envelope for ThorchainSwap events. Allows matching all events by struct."

  defstruct address: nil, data: nil

  @type t :: %__MODULE__{
          address: String.t() | nil,
          data: struct()
        }

  @spec new(String.t() | nil, struct()) :: t()
  def new(address, data), do: %__MODULE__{address: address, data: data}
end
