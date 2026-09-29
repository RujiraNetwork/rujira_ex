defmodule Rujira.Thorchain.Block.Messages.ObservedTxOut do
  @moduledoc """
  A validator's outbound observations (`/types.MsgObservedTxOut`).

  Every observation this message carries is outbound - funds a vault sent.
  `Rujira.Thorchain.Block.observed_txs/1` reads them out with that direction
  already applied.
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
