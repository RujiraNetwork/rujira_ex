defmodule Rujira.Thorchain.Events.Withdraw do
  @moduledoc "A THORChain withdraw event."

  defstruct pool: nil

  @type t :: %__MODULE__{pool: String.t()}

  @spec new(map()) :: {:ok, t()} | {:error, :invalid_attrs}
  def new(%{"pool" => pool}) do
    {:ok, %__MODULE__{pool: pool}}
  end

  def new(_), do: {:error, :invalid_attrs}
end
