defmodule Rujira.Bank.Holder do
  @moduledoc "An owner of an asset and their balance. Use `Rujira.Bank` as the public API."

  alias Cosmos.Bank.V1beta1.Query.Stub
  alias Cosmos.Bank.V1beta1.QueryDenomOwnersRequest
  alias Cosmos.Base.Query.V1beta1.PageRequest
  alias Rujira.Assets
  alias Rujira.Assets.Asset
  alias Rujira.Coin

  use Memoize

  @holders_limit 100

  # --- Struct ---

  defstruct address: nil, balance: nil

  @type t :: %__MODULE__{address: String.t() | nil, balance: Coin.t() | nil}

  # --- Construction ---

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{address: address, balance: %{denom: _, amount: _} = balance}) do
    with {:ok, coin} <- Coin.new(balance) do
      {:ok, %__MODULE__{address: address, balance: coin}}
    end
  end

  def new(_), do: {:error, :invalid_attrs}

  # --- Queries ---

  @doc """
  Memoized list of the top holders of an asset, sorted by balance descending.

  Invalidate with `Memoize.invalidate(Rujira.Bank.Holder, :holders, [asset, limit])`.
  """
  @spec holders(Asset.t(), pos_integer()) :: {:ok, [t()]} | {:error, term()}
  defmemo holders(asset, limit \\ @holders_limit), expires_in: :timer.hours(1) do
    with {:ok, denom} <- Assets.to_native(asset),
         {:ok, owners} <- denom_owners(denom),
         {:ok, holders} <- Rujira.Enum.reduce_while_ok(owners, &new/1) do
      {:ok, holders |> Enum.sort_by(& &1.balance.amount, :desc) |> Enum.take(limit)}
    end
  end

  # --- Private ---

  defp denom_owners(denom, key \\ nil)
  defp denom_owners(_denom, ""), do: {:ok, []}

  defp denom_owners(denom, key) do
    with {:ok, %{denom_owners: owners, pagination: %{next_key: next_key}}} <-
           Rujira.Node.query(&Stub.denom_owners/2, request(denom, key)),
         {:ok, next} <- denom_owners(denom, next_key) do
      {:ok, owners ++ next}
    end
  end

  defp request(denom, nil), do: %QueryDenomOwnersRequest{denom: denom}

  defp request(denom, key),
    do: %QueryDenomOwnersRequest{denom: denom, pagination: %PageRequest{key: key}}
end
