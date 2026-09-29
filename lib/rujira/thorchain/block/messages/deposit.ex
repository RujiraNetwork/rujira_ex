defmodule Rujira.Thorchain.Block.Messages.Deposit do
  @moduledoc "A THORChain deposit message (`/types.MsgDeposit`)."

  alias Rujira.Coin
  alias Rujira.String

  defstruct coins: [], memo: nil, signer: nil

  @type t :: %__MODULE__{
          coins: [Coin.t()],
          memo: String.t() | nil,
          signer: String.t() | nil
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"coins" => coins, "signer" => signer} = attrs) do
    with {:ok, coins} <- Rujira.Enum.reduce_while_ok(List.wrap(coins), &Coin.new/1) do
      {:ok,
       %__MODULE__{
         coins: coins,
         memo: String.nil_if_empty(Map.get(attrs, "memo")),
         signer: signer
       }}
    end
  end

  def new(_attrs), do: {:error, :invalid_attrs}
end
