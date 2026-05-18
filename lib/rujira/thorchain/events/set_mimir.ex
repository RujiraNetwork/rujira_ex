defmodule Rujira.Thorchain.Events.SetMimir do
  @moduledoc "A THORChain governance mimir update event."

  defstruct key: nil, value: nil

  @type t :: %__MODULE__{
          key: String.t(),
          value: String.t() | nil
        }

  @spec new(map()) :: {:ok, t()} | {:error, :malformed}
  def new(%{"key" => key} = attrs) do
    {:ok, %__MODULE__{key: key, value: Map.get(attrs, "value")}}
  end

  def new(_), do: {:error, :malformed}
end
