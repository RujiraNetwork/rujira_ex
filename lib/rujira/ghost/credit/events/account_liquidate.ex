defmodule Rujira.Ghost.Credit.Events.AccountLiquidate do
  @moduledoc "A credit account being liquidated (`wasm-rujira-ghost-credit/account.liquidate`)."

  defstruct owner: nil, address: nil, caller: nil

  @type t :: %__MODULE__{owner: String.t(), address: String.t(), caller: String.t()}

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"owner" => owner, "address" => address, "caller" => caller})
      when is_binary(owner) and is_binary(address) and is_binary(caller) do
    {:ok, %__MODULE__{owner: owner, address: address, caller: caller}}
  end

  def new(_), do: {:error, :invalid_attrs}
end
