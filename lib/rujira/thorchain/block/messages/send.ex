defmodule Rujira.Thorchain.Block.Messages.Send do
  @moduledoc """
  A bank send message, moving bank denoms between THOR addresses.

  THORChain's own `/types.MsgSend` and the Cosmos SDK's
  `/cosmos.bank.v1beta1.MsgSend` render the same shape, and the chain accepts
  both, so one struct covers either `@type`.
  """

  alias Rujira.Coin

  defstruct from: nil, to: nil, coins: []

  @type t :: %__MODULE__{
          from: String.t() | nil,
          to: String.t() | nil,
          coins: [Coin.t()]
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"from_address" => from, "to_address" => to} = attrs) do
    with {:ok, coins} <-
           Rujira.Enum.reduce_while_ok(List.wrap(Map.get(attrs, "amount")), &Coin.new/1) do
      {:ok, %__MODULE__{from: from, to: to, coins: coins}}
    end
  end

  def new(_attrs), do: {:error, :invalid_attrs}
end
