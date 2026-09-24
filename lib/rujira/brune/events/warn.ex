defmodule Rujira.Brune.Events.Warn do
  @moduledoc "A protocol warning event (`wasm-rujira-brune/warn`)."

  defstruct message: nil

  @type t :: %__MODULE__{message: String.t()}

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"message" => message}), do: {:ok, %__MODULE__{message: message}}
  def new(_), do: {:error, :invalid_attrs}
end
