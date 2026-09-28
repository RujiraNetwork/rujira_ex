defmodule Rujira.Bank.Holder do
  @moduledoc "An owner of an asset and their balance. Use `Rujira.Bank` as the public API."

  alias Cosmos.Bank.V1beta1.Query.Stub
  alias Cosmos.Bank.V1beta1.QueryDenomOwnersRequest
  alias Cosmos.Base.Query.V1beta1.PageRequest
  alias Rujira.Assets
  alias Rujira.Assets.Asset
  alias Rujira.Cache
  alias Rujira.Coin
  alias Rujira.Node

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

  @doc "Every holder of an asset, in node order, cached per `Rujira.Cache`."
  @spec holders(Asset.t()) :: {:ok, [t()]} | {:error, term()}
  def holders(asset), do: holders(asset, [])

  @doc "As `holders/1`, read at `opts[:height]` or, without one, at the head."
  @spec holders(Asset.t(), Node.opts()) :: {:ok, [t()]} | {:error, term()}
  def holders(asset, opts) do
    with {:ok, denom} <- Assets.to_native(asset),
         {:ok, opts} <- Cache.pin(opts) do
      Cache.fetch(
        {__MODULE__, :holders, [denom]},
        [{:denom_transfers, denom}],
        opts,
        fn _height -> fetch_holders(denom, opts) end
      )
    end
  end

  # --- Private ---

  defp fetch_holders(denom, opts) do
    with {:ok, owners} <- denom_owners(denom, nil, opts) do
      Rujira.Enum.reduce_while_ok(owners, &new/1)
    end
  end

  defp denom_owners(_denom, "", _opts), do: {:ok, []}

  defp denom_owners(denom, key, opts) do
    with {:ok, %{denom_owners: owners, pagination: %{next_key: next_key}}} <-
           Node.query(&Stub.denom_owners/3, request(denom, key), opts),
         {:ok, next} <- denom_owners(denom, next_key, opts) do
      {:ok, owners ++ next}
    end
  end

  defp request(denom, nil), do: %QueryDenomOwnersRequest{denom: denom}

  defp request(denom, key),
    do: %QueryDenomOwnersRequest{denom: denom, pagination: %PageRequest{key: key}}
end
