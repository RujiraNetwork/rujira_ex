defmodule Rujira.Thorchain.Events.Event do
  @moduledoc "Protocol-level envelope for THORChain events. Allows matching all THORChain events by struct."

  defstruct data: nil

  @type t :: %__MODULE__{data: struct()}

  @spec new(struct()) :: t()
  def new(data), do: %__MODULE__{data: data}
end
