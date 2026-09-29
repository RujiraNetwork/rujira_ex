defmodule Rujira.Thorchain.Block.Messages.UpdateAdmin do
  @moduledoc "A CosmWasm admin change (`/cosmwasm.wasm.v1.MsgUpdateAdmin`)."

  alias Rujira.String

  defstruct sender: nil, new_admin: nil, contract: nil

  @type t :: %__MODULE__{
          sender: String.t() | nil,
          new_admin: String.t() | nil,
          contract: String.t() | nil
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"sender" => sender, "contract" => contract} = attrs) do
    {:ok,
     %__MODULE__{
       sender: sender,
       new_admin: String.nil_if_empty(Map.get(attrs, "new_admin")),
       contract: contract
     }}
  end

  def new(_attrs), do: {:error, :invalid_attrs}
end
