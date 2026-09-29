defmodule Rujira.Thorchain.Block.Messages.StoreCode do
  @moduledoc """
  A CosmWasm code upload (`/cosmwasm.wasm.v1.MsgStoreCode`).

  The `wasm_byte_code` the message carries is the contract binary - megabytes
  of it, and no part of the chain data a consumer reads - so it is not kept.
  What is kept is who uploaded it and, when the message set one, the
  instantiate permission as the chain rendered it.
  """

  defstruct sender: nil, instantiate_permission: nil

  @type t :: %__MODULE__{
          sender: String.t() | nil,
          instantiate_permission: map() | nil
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"sender" => sender} = attrs) do
    {:ok,
     %__MODULE__{
       sender: sender,
       instantiate_permission: permission(Map.get(attrs, "instantiate_permission"))
     }}
  end

  def new(_attrs), do: {:error, :invalid_attrs}

  defp permission(%{} = permission), do: permission
  defp permission(_permission), do: nil
end
