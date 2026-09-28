defmodule Rujira.Ghost.Credit.Events.AccountMsgRepay do
  @moduledoc "A credit account repaying a Ghost vault (`wasm-rujira-ghost-credit/account.msg/repay`)."

  alias Rujira.Coin

  defstruct amount: nil

  @type t :: %__MODULE__{amount: Coin.t()}

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"amount" => amount}) when is_binary(amount) do
    with {:ok, amount} <- coin(amount) do
      {:ok, %__MODULE__{amount: amount}}
    end
  end

  def new(_), do: {:error, :invalid_attrs}

  defp coin(value) do
    case Coin.parse(value) do
      {:ok, [coin]} -> {:ok, coin}
      {:ok, _} -> {:error, :invalid_coin_format}
      {:error, _} = err -> err
    end
  end
end
