defmodule Rujira.Thorchain.Block.Messages.MigrateContract do
  @moduledoc """
  A CosmWasm migrate message (`/cosmwasm.wasm.v1.MsgMigrateContract`).

  `code_id` is the code the contract migrates *to*; `msg` is the migrate
  payload as a map, see `Rujira.Thorchain.Block.Payload`.
  """

  alias Rujira.Math
  alias Rujira.Thorchain.Block.Payload

  defstruct sender: nil, contract: nil, code_id: nil, msg: nil

  @type t :: %__MODULE__{
          sender: String.t() | nil,
          contract: String.t() | nil,
          code_id: integer() | nil,
          msg: map() | nil
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"sender" => sender, "contract" => contract, "code_id" => code_id} = attrs) do
    with {:ok, code_id} <- Math.to_integer(code_id),
         {:ok, msg} <- Payload.decode(Map.get(attrs, "msg")) do
      {:ok, %__MODULE__{sender: sender, contract: contract, code_id: code_id, msg: msg}}
    end
  end

  def new(_attrs), do: {:error, :invalid_attrs}
end
