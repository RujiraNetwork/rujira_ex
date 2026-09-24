defmodule Rujira.Brune.Events.Burn do
  @moduledoc "A Brune token burn event (`wasm-rujira-brune/burn`)."

  alias Rujira.Coin

  defstruct sender: nil, coin: nil

  @type t :: %__MODULE__{
          sender: String.t(),
          coin: Coin.t()
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"sender" => sender, "amount" => amount, "denom" => denom}) do
    with {:ok, coin} <- Coin.new(denom, amount) do
      {:ok, %__MODULE__{sender: sender, coin: coin}}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
