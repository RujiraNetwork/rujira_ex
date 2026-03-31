defmodule Rujira.Events.Event do
  @moduledoc "Default event struct for unrecognized or not-yet-implemented events."

  defstruct [:type, :attributes]

  @type t :: %__MODULE__{
          type: String.t(),
          attributes: map()
        }

  @spec new(String.t(), map()) :: t()
  def new(type, attributes) do
    %__MODULE__{type: type, attributes: attributes}
  end
end
