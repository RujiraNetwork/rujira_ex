defmodule Rujira.Ghost.Vault.Borrower do
  @moduledoc """
  A whitelisted borrower's position on a Ghost vault.

  Constructed from the vault's `borrower` query response.
  """

  alias Rujira.Amount
  alias Rujira.Math

  defstruct address: nil,
            denom: nil,
            limit: 0,
            current: 0,
            shares: Decimal.new(0),
            available: 0

  @type t :: %__MODULE__{
          address: String.t() | nil,
          denom: String.t() | nil,
          limit: Amount.t(),
          current: Amount.t(),
          shares: Decimal.t(),
          available: Amount.t()
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{
        "addr" => addr,
        "denom" => denom,
        "limit" => limit,
        "current" => current,
        "shares" => shares,
        "available" => available
      }) do
    with {:ok, limit} <- Amount.new(limit),
         {:ok, current} <- Amount.new(current),
         {:ok, shares} <- Math.to_decimal(shares),
         {:ok, available} <- Amount.new(available) do
      {:ok,
       %__MODULE__{
         address: addr,
         denom: denom,
         limit: limit,
         current: current,
         shares: shares,
         available: available
       }}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
