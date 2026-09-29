defmodule Rujira.Thorchain.Block.Messages.ExecuteContract do
  @moduledoc """
  A CosmWasm execute message (`/cosmwasm.wasm.v1.MsgExecuteContract`).

  `msg` is the contract payload as a map - see
  `Rujira.Thorchain.Block.Payload`.
  """

  alias Rujira.Coin
  alias Rujira.Thorchain.Block.Payload

  defstruct sender: nil, contract: nil, msg: nil, funds: []

  @type t :: %__MODULE__{
          sender: String.t() | nil,
          contract: String.t() | nil,
          msg: map() | nil,
          funds: [Coin.t()]
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"sender" => sender, "contract" => contract} = attrs) do
    with {:ok, msg} <- Payload.decode(Map.get(attrs, "msg")),
         {:ok, funds} <-
           Rujira.Enum.reduce_while_ok(List.wrap(Map.get(attrs, "funds")), &Coin.new/1) do
      {:ok, %__MODULE__{sender: sender, contract: contract, msg: msg, funds: funds}}
    end
  end

  def new(_attrs), do: {:error, :invalid_attrs}
end
