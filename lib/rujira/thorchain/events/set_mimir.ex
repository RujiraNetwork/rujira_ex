defmodule Rujira.Thorchain.Events.SetMimir do
  @moduledoc "A THORChain governance mimir update event."

  defstruct key: nil, value: nil

  @type t :: %__MODULE__{
          key: String.t(),
          value: String.t()
        }

  @spec new(map()) :: {:ok, t()} | {:error, :invalid_attrs}
  def new(%{"key" => key, "value" => value}) do
    {:ok, %__MODULE__{key: key, value: value}}
  end

  def new(_), do: {:error, :invalid_attrs}
end
