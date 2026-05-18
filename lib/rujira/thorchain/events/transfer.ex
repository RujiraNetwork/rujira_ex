defmodule Rujira.Thorchain.Events.Transfer do
  @moduledoc "A THORChain token transfer event."

  alias Rujira.Amount

  defstruct sender: nil, recipient: nil, amount: 0

  @type t :: %__MODULE__{
          sender: String.t(),
          recipient: String.t(),
          amount: Amount.t()
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"sender" => sender, "recipient" => recipient, "amount" => amount}) do
    with {:ok, amount} <- Amount.new(amount) do
      {:ok, %__MODULE__{sender: sender, recipient: recipient, amount: amount}}
    end
  end

  def new(_), do: {:error, :malformed}
end
