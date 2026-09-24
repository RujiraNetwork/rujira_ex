defmodule Rujira.Staking.Events.LiquidUnbond do
  @moduledoc "A staking liquid unbond event (`wasm-rujira-staking/liquid.unbond`)."

  alias Rujira.Amount

  defstruct owner: nil, shares: 0, returned: 0

  @type t :: %__MODULE__{
          owner: String.t(),
          shares: Amount.t(),
          returned: Amount.t()
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"owner" => owner, "shares" => shares, "returned" => returned}) do
    with {:ok, shares} <- Amount.new(shares),
         {:ok, returned} <- Amount.new(returned) do
      {:ok, %__MODULE__{owner: owner, shares: shares, returned: returned}}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
