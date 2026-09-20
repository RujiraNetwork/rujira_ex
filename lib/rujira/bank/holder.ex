defmodule Rujira.Bank.Holder do
  @moduledoc "An owner of a denom and their balance."

  alias Rujira.Amount

  defstruct address: nil, amount: 0

  @type t :: %__MODULE__{address: String.t() | nil, amount: Amount.t()}

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{address: address, balance: %{amount: amount}}) do
    with {:ok, amount} <- Amount.new(amount) do
      {:ok, %__MODULE__{address: address, amount: amount}}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
