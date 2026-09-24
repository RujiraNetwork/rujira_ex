defmodule Rujira.Staking.Events.Settle do
  @moduledoc "A staking pool settle event (`wasm-rujira-staking/settle`)."

  alias Rujira.Amount

  defstruct returned: 0

  @type t :: %__MODULE__{
          returned: Amount.t()
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"returned" => returned}) do
    with {:ok, returned} <- Amount.new(returned) do
      {:ok, %__MODULE__{returned: returned}}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
