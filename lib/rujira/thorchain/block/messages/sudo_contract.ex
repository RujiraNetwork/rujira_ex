defmodule Rujira.Thorchain.Block.Messages.SudoContract do
  @moduledoc """
  A CosmWasm privileged call (`/cosmwasm.wasm.v1.MsgSudoContract`).

  Signed by the chain's governance `authority`, not by the contract's admin.
  `msg` is the sudo payload as a map, see `Rujira.Thorchain.Block.Payload`.
  """

  alias Rujira.Thorchain.Block.Payload

  defstruct authority: nil, contract: nil, msg: nil

  @type t :: %__MODULE__{
          authority: String.t() | nil,
          contract: String.t() | nil,
          msg: map() | nil
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"authority" => authority, "contract" => contract} = attrs) do
    with {:ok, msg} <- Payload.decode(Map.get(attrs, "msg")) do
      {:ok, %__MODULE__{authority: authority, contract: contract, msg: msg}}
    end
  end

  def new(_attrs), do: {:error, :invalid_attrs}
end
