defmodule Rujira.Thorchain.Block.Observation do
  @moduledoc """
  One layer-1 transaction a block observed, with its direction and position.

  `inbound` is the direction the observation was made in - `true` for funds
  arriving at a vault, `false` for funds a vault sent - taken from the quorum
  message's own flag or, for the per-validator messages, from which of
  `/types.MsgObservedTxIn` and `/types.MsgObservedTxOut` carried it.

  `tx_idx` is the block position of the transaction the observation was made
  in, the same index `Rujira.Thorchain.Block.Tx` and the block's events carry.

  See `Rujira.Thorchain.Block.observed_txs/1`.
  """

  alias Rujira.Thorchain.Block.Messages.ObservedTx
  alias Rujira.Thorchain.Block.Messages.ObservedTxIn
  alias Rujira.Thorchain.Block.Messages.ObservedTxOut
  alias Rujira.Thorchain.Block.Messages.ObservedTxQuorum

  defstruct tx_idx: 0, inbound: true, tx: nil

  @type t :: %__MODULE__{
          tx_idx: integer(),
          inbound: boolean(),
          tx: ObservedTx.t() | nil
        }

  @doc """
  Every observation one message carries, in the order it carries them.

  A message that observes nothing - every type but the three observation ones -
  carries none, so this is `[]`.
  """
  @spec from_message(integer(), struct()) :: [t()]
  def from_message(tx_idx, %ObservedTxQuorum{inbound: inbound, tx: %ObservedTx{} = tx}),
    do: [new(tx_idx, inbound, tx)]

  def from_message(tx_idx, %ObservedTxIn{txs: txs}),
    do: Enum.map(txs, &new(tx_idx, true, &1))

  def from_message(tx_idx, %ObservedTxOut{txs: txs}),
    do: Enum.map(txs, &new(tx_idx, false, &1))

  def from_message(_tx_idx, _message), do: []

  defp new(tx_idx, inbound, tx),
    do: %__MODULE__{tx_idx: tx_idx, inbound: inbound, tx: tx}
end
