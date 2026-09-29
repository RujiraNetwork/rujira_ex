defmodule Rujira.Thorchain.Block.Messages.ObservedTxIn do
  @moduledoc """
  A validator's inbound observations (`/types.MsgObservedTxIn`).

  Every observation this message carries is inbound - funds arriving at a
  vault. `Rujira.Thorchain.Block.observed_txs/1` reads them out with that
  direction already applied.
  """

  alias Rujira.Thorchain.Block.Messages.ObservedTx

  defstruct txs: [], signer: nil

  @type t :: %__MODULE__{txs: [ObservedTx.t()], signer: String.t() | nil}

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"txs" => txs} = attrs) do
    with {:ok, txs} <- ObservedTx.new_list(txs) do
      {:ok, %__MODULE__{txs: txs, signer: Map.get(attrs, "signer")}}
    end
  end

  def new(_attrs), do: {:error, :invalid_attrs}
end
