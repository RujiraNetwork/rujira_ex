defmodule Rujira.ThorchainSwap.Events.Swap do
  @moduledoc "A ThorchainSwap swap event (`wasm-rujira-thorchain-swap/swap`)."

  alias Rujira.Coin

  defstruct amount: nil,
            quote_return: nil,
            min_return: nil,
            reserve_fee: nil,
            amm_fee: nil,
            returned: nil,
            memo: nil

  @type t :: %__MODULE__{
          amount: Coin.t() | nil,
          quote_return: Coin.t() | nil,
          min_return: Coin.t() | nil,
          reserve_fee: Coin.t() | nil,
          amm_fee: Coin.t() | nil,
          returned: Coin.t() | nil,
          memo: String.t() | nil
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{
        "amount" => amount,
        "quote_return" => quote_return,
        "min_return" => min_return,
        "reserve_fee" => reserve_fee,
        "amm_fee" => amm_fee,
        "returned" => returned,
        "memo" => memo
      }) do
    with {:ok, amount} <- Coin.parse(amount),
         {:ok, quote_return} <- Coin.parse(quote_return),
         {:ok, min_return} <- Coin.parse(min_return),
         {:ok, reserve_fee} <- Coin.parse(reserve_fee),
         {:ok, amm_fee} <- Coin.parse(amm_fee),
         {:ok, returned} <- Coin.parse(returned) do
      {:ok,
       %__MODULE__{
         amount: List.first(amount),
         quote_return: List.first(quote_return),
         min_return: List.first(min_return),
         reserve_fee: List.first(reserve_fee),
         amm_fee: List.first(amm_fee),
         returned: List.first(returned),
         memo: memo
       }}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
