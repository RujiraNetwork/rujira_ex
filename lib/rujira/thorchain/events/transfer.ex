defmodule Rujira.Thorchain.Events.Transfer do
  @moduledoc "A THORChain (cosmos bank) token transfer event."

  alias Rujira.Coin

  defstruct sender: nil, recipient: nil, coins: []

  @type t :: %__MODULE__{
          sender: String.t(),
          recipient: String.t(),
          coins: [Coin.t()]
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"sender" => sender, "recipient" => recipient, "amount" => amount}) do
    with {:ok, coins} <- Coin.parse(amount) do
      {:ok, %__MODULE__{sender: sender, recipient: recipient, coins: coins}}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
