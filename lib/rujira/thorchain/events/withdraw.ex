defmodule Rujira.Thorchain.Events.Withdraw do
  @moduledoc "A THORChain withdraw event."

  defstruct pool: nil

  @type t :: %__MODULE__{pool: String.t()}

  @spec new(map()) :: {:ok, t()}
  def new(%{"pool" => pool}) do
    {:ok, %__MODULE__{pool: pool}}
  end
end
