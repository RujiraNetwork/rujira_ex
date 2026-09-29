defmodule Rujira.Thorchain.Block.Messages.ClearAdmin do
  @moduledoc """
  A CosmWasm admin removal (`/cosmwasm.wasm.v1.MsgClearAdmin`).

  Leaves the contract immutable - there is no admin to migrate it afterwards.
  """

  defstruct sender: nil, contract: nil

  @type t :: %__MODULE__{sender: String.t() | nil, contract: String.t() | nil}

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"sender" => sender, "contract" => contract}),
    do: {:ok, %__MODULE__{sender: sender, contract: contract}}

  def new(_attrs), do: {:error, :invalid_attrs}
end
