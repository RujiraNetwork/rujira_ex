defmodule Rujira.Ghost.Credit.Events.AccountMsgBorrow do
  @moduledoc "A credit account borrowing from a Ghost vault (`wasm-rujira-ghost-credit/account.msg/borrow`)."

  alias Rujira.Coin

  defstruct amount: nil

  @type t :: %__MODULE__{amount: Coin.t()}

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"amount" => amount}) when is_binary(amount) do
    with {:ok, amount} <- Coin.parse_single(amount) do
      {:ok, %__MODULE__{amount: amount}}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
