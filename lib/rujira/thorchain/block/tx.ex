defmodule Rujira.Thorchain.Block.Tx do
  @moduledoc """
  One transaction of a block, with its messages decoded.

  `idx` is the transaction's position in the block - the same index the block's
  events carry as `tx_idx`, so an event and the transaction that emitted it
  line up on it.

  ## Result

  `code` is the transaction's result code: `0` is success, and anything else
  means the transaction failed and its messages had no effect. A transaction
  the node sent no result for has a `nil` `code` - not a `0` that would read as
  success.

  ## Envelopes

  thornode renders a transaction as one of two JSON envelopes, and both end up
  here as the same struct:

    * an injected enshrined-bifrost transaction is `{"messages": [...]}` alone,
      with no memo and no signatures;
    * a signed transaction is `{"body": {"messages", "memo"}, "auth_info",
      "signatures"}`.

  `memo` is the transaction-level memo, `nil` when it is empty or the envelope
  has none. A message's own memo - a `Rujira.Thorchain.Block.Messages.Deposit`'s
  swap memo, say - is that message's field, not this one.

  `auth_info` and `signatures` are signing plumbing rather than chain data a
  consumer reads, so they are not kept.

  A transaction whose JSON does not decode keeps its `hash` and `code` with no
  messages, after a warning: a transaction the library cannot read costs that
  transaction's detail, never the block. A transaction the node sent no JSON
  for at all is not an error and is not warned about - there was nothing to
  decode.
  """

  alias Rujira.Logger
  alias Rujira.String
  alias Rujira.Thorchain.Block.Messages
  alias Thorchain.Types.BlockTxResult
  alias Thorchain.Types.QueryBlockTx

  # --- Struct ---

  defstruct idx: 0, hash: nil, code: 0, memo: nil, messages: []

  @type t :: %__MODULE__{
          idx: non_neg_integer(),
          hash: String.t() | nil,
          code: integer() | nil,
          memo: String.t() | nil,
          messages: [Messages.t()]
        }

  # --- Construction ---

  @doc "The transaction at `idx` of the block at `height`. Never fails."
  @spec new(QueryBlockTx.t(), non_neg_integer(), non_neg_integer()) :: t()
  def new(%QueryBlockTx{hash: hash, tx: raw, result: result}, idx, height) do
    body = decode(raw, height, idx)

    %__MODULE__{
      idx: idx,
      hash: String.nil_if_empty(hash),
      code: code(result),
      memo: memo(body),
      messages: messages(body, height, idx)
    }
  end

  # --- Private ---

  defp code(%BlockTxResult{code: code}), do: code
  defp code(_result), do: nil

  defp decode(nil, _height, _idx), do: %{}
  defp decode("", _height, _idx), do: %{}

  defp decode(raw, height, idx) when is_binary(raw) do
    case JSON.decode(raw) do
      {:ok, %{} = body} -> body
      _ -> undecodable(height, idx)
    end
  end

  defp decode(_raw, height, idx), do: undecodable(height, idx)

  defp undecodable(height, idx) do
    Logger.warning(__MODULE__, "undecodable tx height=#{height} tx_idx=#{idx}")
    %{}
  end

  defp memo(%{"body" => %{"memo" => memo}}) when is_binary(memo), do: String.nil_if_empty(memo)
  defp memo(_body), do: nil

  defp messages(%{"messages" => msgs}, height, idx) when is_list(msgs),
    do: parse(msgs, height, idx)

  defp messages(%{"body" => %{"messages" => msgs}}, height, idx) when is_list(msgs),
    do: parse(msgs, height, idx)

  defp messages(_body, _height, _idx), do: []

  defp parse(msgs, height, idx) do
    msgs
    |> Enum.with_index()
    |> Enum.map(fn {msg, msg_idx} -> Messages.parse(msg, height, idx, msg_idx) end)
  end
end
