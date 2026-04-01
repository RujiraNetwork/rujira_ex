defmodule Rujira.Fin.Events.Event do
  @moduledoc "Protocol-level envelope for FIN events. Allows matching all FIN events by struct."

  defstruct [:address, :data]

  @type t :: %__MODULE__{
          address: String.t() | nil,
          data: struct()
        }

  @spec new(String.t() | nil, struct()) :: t()
  def new(address, data), do: %__MODULE__{address: address, data: data}
end
