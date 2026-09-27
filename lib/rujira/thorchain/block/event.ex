defmodule Rujira.Thorchain.Block.Event do
  @moduledoc """
  One event of a block, placed in the order the node executed it.

  `tx_idx` orders the stages and the transactions between them, `event_idx`
  counts from 0 within the node's list for that stage or transaction. Sorting
  by `{tx_idx, event_idx}` replays the block in execution order - see
  `Rujira.Thorchain.Block` for the sentinel `tx_idx` of each non-tx stage.

  `event` is whatever `Rujira.Events.parse/1` returned for the raw event: a
  protocol envelope for a recognised event, or a bare `Rujira.Events.Event` for
  an unrecognised - or unparsable - one, so no event of a block is ever lost.
  """

  defstruct tx_idx: 0, event_idx: 0, txhash: nil, stage: :tx, event: nil

  @typedoc """
  The block stage that emitted the event.

    * `:pre_block` - `finalize_block_events`, before any transaction runs
    * `:begin` - `begin_block_events`
    * `:tx` - a transaction's own result events
    * `:end` - `end_block_events`, after every transaction
  """
  @type stage :: :pre_block | :begin | :tx | :end

  @type t :: %__MODULE__{
          tx_idx: integer(),
          event_idx: non_neg_integer(),
          txhash: String.t() | nil,
          stage: stage(),
          event: struct() | nil
        }

  # --- Construction ---

  @doc "The event at `event_idx` of `stage`. `txhash` is `nil` for a non-tx stage."
  @spec new(stage(), integer(), non_neg_integer(), String.t() | nil, struct()) :: t()
  def new(stage, tx_idx, event_idx, txhash, event) do
    %__MODULE__{
      tx_idx: tx_idx,
      event_idx: event_idx,
      txhash: txhash,
      stage: stage,
      event: event
    }
  end
end
