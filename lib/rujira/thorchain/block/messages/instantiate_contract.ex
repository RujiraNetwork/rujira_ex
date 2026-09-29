defmodule Rujira.Thorchain.Block.Messages.InstantiateContract do
  @moduledoc """
  A CosmWasm instantiate message (`/cosmwasm.wasm.v1.MsgInstantiateContract`).

  An empty `admin` is `nil` - the contract is immutable. `msg` is the
  instantiate payload as a map, see `Rujira.Thorchain.Block.Payload`.
  """

  alias Rujira.Coin
  alias Rujira.Math
  alias Rujira.String
  alias Rujira.Thorchain.Block.Payload

  defstruct sender: nil, admin: nil, code_id: nil, label: nil, msg: nil, funds: []

  @type t :: %__MODULE__{
          sender: String.t() | nil,
          admin: String.t() | nil,
          code_id: integer() | nil,
          label: String.t() | nil,
          msg: map() | nil,
          funds: [Coin.t()]
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"sender" => sender, "code_id" => code_id} = attrs) do
    with {:ok, code_id} <- Math.to_integer(code_id),
         {:ok, msg} <- Payload.decode(Map.get(attrs, "msg")),
         {:ok, funds} <-
           Rujira.Enum.reduce_while_ok(List.wrap(Map.get(attrs, "funds")), &Coin.new/1) do
      {:ok,
       %__MODULE__{
         sender: sender,
         admin: String.nil_if_empty(Map.get(attrs, "admin")),
         code_id: code_id,
         label: String.nil_if_empty(Map.get(attrs, "label")),
         msg: msg,
         funds: funds
       }}
    end
  end

  def new(_attrs), do: {:error, :invalid_attrs}
end
