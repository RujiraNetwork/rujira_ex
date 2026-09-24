defmodule Rujira.Brune.Events.Mint do
  @moduledoc "A Brune token mint event (`wasm-rujira-brune/mint`)."

  alias Rujira.Coin

  defstruct recipient: nil, coin: nil

  @type t :: %__MODULE__{
          recipient: String.t(),
          coin: Coin.t()
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"recipient" => recipient, "amount" => amount, "denom" => denom}) do
    with {:ok, coin} <- Coin.new(denom, amount) do
      {:ok, %__MODULE__{recipient: recipient, coin: coin}}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
