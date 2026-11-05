defmodule Rujira.Thorchain.Block.Messages do
  @moduledoc """
  Decodes one transaction message into its typed struct.

  A message is the `@type` + snake_case JSON thornode renders, with every
  amount a string. `parse/4` dispatches on `@type`: a type this library holds a
  struct for is built into it, and every other type becomes a
  `Rujira.Thorchain.Block.Messages.Message` carrying the `@type` and the map
  the node sent.

  A message that does not parse is handled by why it failed, as
  `Rujira.Events.data_error?/1` tells - the same rule a block's events follow:

  - **The data's fault** - an `:invalid_*` reason, such as a body missing a
    field. The message is logged - in the same style as an unparsed event -
    and kept as a generic message, so a message the library mis-reads costs
    that message's detail, never the block.
  - **Anything else** - a node read that failed while resolving one of the
    message's coins (an `x/` denom's metadata), say. `parse/4` returns
    `{:error, reason}` with the reason unchanged, after a warning, and the
    block it belongs to fails rather than hiding the gap.

  The types with a struct of their own:

  | `@type` | Struct |
  |---------|--------|
  | `/types.MsgDeposit` | `Rujira.Thorchain.Block.Messages.Deposit` |
  | `/types.MsgSend` | `Rujira.Thorchain.Block.Messages.Send` |
  | `/cosmos.bank.v1beta1.MsgSend` | `Rujira.Thorchain.Block.Messages.Send` |
  | `/cosmwasm.wasm.v1.MsgExecuteContract` | `Rujira.Thorchain.Block.Messages.ExecuteContract` |
  | `/cosmwasm.wasm.v1.MsgInstantiateContract` | `Rujira.Thorchain.Block.Messages.InstantiateContract` |
  | `/cosmwasm.wasm.v1.MsgInstantiateContract2` | `Rujira.Thorchain.Block.Messages.InstantiateContract2` |
  | `/cosmwasm.wasm.v1.MsgMigrateContract` | `Rujira.Thorchain.Block.Messages.MigrateContract` |
  | `/cosmwasm.wasm.v1.MsgStoreCode` | `Rujira.Thorchain.Block.Messages.StoreCode` |
  | `/cosmwasm.wasm.v1.MsgUpdateAdmin` | `Rujira.Thorchain.Block.Messages.UpdateAdmin` |
  | `/cosmwasm.wasm.v1.MsgClearAdmin` | `Rujira.Thorchain.Block.Messages.ClearAdmin` |
  | `/cosmwasm.wasm.v1.MsgSudoContract` | `Rujira.Thorchain.Block.Messages.SudoContract` |
  | `/types.MsgObservedTxQuorum` | `Rujira.Thorchain.Block.Messages.ObservedTxQuorum` |
  | `/types.MsgObservedTxIn` | `Rujira.Thorchain.Block.Messages.ObservedTxIn` |
  | `/types.MsgObservedTxOut` | `Rujira.Thorchain.Block.Messages.ObservedTxOut` |
  """

  alias Rujira.Thorchain.Block.Degrade
  alias Rujira.Thorchain.Block.Messages.ClearAdmin
  alias Rujira.Thorchain.Block.Messages.Deposit
  alias Rujira.Thorchain.Block.Messages.ExecuteContract
  alias Rujira.Thorchain.Block.Messages.InstantiateContract
  alias Rujira.Thorchain.Block.Messages.InstantiateContract2
  alias Rujira.Thorchain.Block.Messages.Message
  alias Rujira.Thorchain.Block.Messages.MigrateContract
  alias Rujira.Thorchain.Block.Messages.ObservedTxIn
  alias Rujira.Thorchain.Block.Messages.ObservedTxOut
  alias Rujira.Thorchain.Block.Messages.ObservedTxQuorum
  alias Rujira.Thorchain.Block.Messages.Send
  alias Rujira.Thorchain.Block.Messages.StoreCode
  alias Rujira.Thorchain.Block.Messages.SudoContract
  alias Rujira.Thorchain.Block.Messages.UpdateAdmin

  @type t ::
          ClearAdmin.t()
          | Deposit.t()
          | ExecuteContract.t()
          | InstantiateContract.t()
          | InstantiateContract2.t()
          | Message.t()
          | MigrateContract.t()
          | ObservedTxIn.t()
          | ObservedTxOut.t()
          | ObservedTxQuorum.t()
          | Send.t()
          | StoreCode.t()
          | SudoContract.t()
          | UpdateAdmin.t()

  @doc """
  The message at `msg_idx` of the transaction at `tx_idx`, typed.

  `height` and the two indices place the message in its block, for the warning
  a message that does not parse is logged with.

  A message whose data does not parse is `{:ok, message}` with the generic
  `Rujira.Thorchain.Block.Messages.Message`; any other failure is
  `{:error, reason}` - see the moduledoc.
  """
  @spec parse(term(), non_neg_integer(), non_neg_integer(), non_neg_integer()) ::
          {:ok, t()} | {:error, term()}
  def parse(%{"@type" => type} = msg, height, tx_idx, msg_idx) when is_binary(type) do
    case new(type, msg) do
      {:ok, data} -> {:ok, data}
      {:error, reason} -> degrade(type, msg, reason, {height, tx_idx, msg_idx})
      :pass -> {:ok, Message.new(type, msg)}
    end
  end

  def parse(%{} = msg, _height, _tx_idx, _msg_idx), do: {:ok, Message.new(nil, msg)}

  def parse(msg, height, tx_idx, msg_idx),
    do: degrade(nil, %{"value" => msg}, {:invalid_message, msg}, {height, tx_idx, msg_idx})

  # --- Private ---

  defp new("/types.MsgDeposit", msg), do: Deposit.new(msg)
  defp new("/types.MsgSend", msg), do: Send.new(msg)
  defp new("/cosmos.bank.v1beta1.MsgSend", msg), do: Send.new(msg)
  defp new("/cosmwasm.wasm.v1.MsgExecuteContract", msg), do: ExecuteContract.new(msg)
  defp new("/cosmwasm.wasm.v1.MsgInstantiateContract", msg), do: InstantiateContract.new(msg)
  defp new("/cosmwasm.wasm.v1.MsgInstantiateContract2", msg), do: InstantiateContract2.new(msg)
  defp new("/cosmwasm.wasm.v1.MsgMigrateContract", msg), do: MigrateContract.new(msg)
  defp new("/cosmwasm.wasm.v1.MsgStoreCode", msg), do: StoreCode.new(msg)
  defp new("/cosmwasm.wasm.v1.MsgUpdateAdmin", msg), do: UpdateAdmin.new(msg)
  defp new("/cosmwasm.wasm.v1.MsgClearAdmin", msg), do: ClearAdmin.new(msg)
  defp new("/cosmwasm.wasm.v1.MsgSudoContract", msg), do: SudoContract.new(msg)
  defp new("/types.MsgObservedTxQuorum", msg), do: ObservedTxQuorum.new(msg)
  defp new("/types.MsgObservedTxIn", msg), do: ObservedTxIn.new(msg)
  defp new("/types.MsgObservedTxOut", msg), do: ObservedTxOut.new(msg)
  defp new(_type, _msg), do: :pass

  defp degrade(type, msg, reason, {height, tx_idx, msg_idx}) do
    Degrade.degrade(
      reason,
      __MODULE__,
      "message",
      "height=#{height} tx_idx=#{tx_idx} msg_idx=#{msg_idx} type=#{type}",
      fn -> Message.new(type, msg) end
    )
  end
end
