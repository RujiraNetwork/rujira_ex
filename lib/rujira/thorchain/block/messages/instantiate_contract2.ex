defmodule Rujira.Thorchain.Block.Messages.InstantiateContract2 do
  @moduledoc """
  A CosmWasm predictable-address instantiate
  (`/cosmwasm.wasm.v1.MsgInstantiateContract2`).

  `Rujira.Thorchain.Block.Messages.InstantiateContract` plus the two fields
  that make the address predictable: `salt`, kept base64 as the chain renders
  the bytes, and `fix_msg`, which folds `msg` into the address when set.
  """

  alias Rujira.Coin
  alias Rujira.Math
  alias Rujira.String
  alias Rujira.Thorchain.Block.Payload

  defstruct sender: nil,
            admin: nil,
            code_id: nil,
            label: nil,
            msg: nil,
            funds: [],
            salt: nil,
            fix_msg: false

  @type t :: %__MODULE__{
          sender: String.t() | nil,
          admin: String.t() | nil,
          code_id: integer() | nil,
          label: String.t() | nil,
          msg: map() | nil,
          funds: [Coin.t()],
          salt: String.t() | nil,
          fix_msg: boolean()
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
         funds: funds,
         salt: String.nil_if_empty(Map.get(attrs, "salt")),
         fix_msg: Map.get(attrs, "fix_msg") == true
       }}
    end
  end

  def new(_attrs), do: {:error, :invalid_attrs}
end
