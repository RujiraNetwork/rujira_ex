defmodule Rujira.Ghost.Credit.Events.AccountMsgTransfer do
  @moduledoc """
  A credit account transferred to a new owner
  (`wasm-rujira-ghost-credit/account.msg/transfer`).

  The recipient is read from the attribute key the contract actually emits,
  `to_adrecipientdress` - a misspelling upstream, kept here because it is what is
  on chain.
  """

  defstruct recipient: nil

  @type t :: %__MODULE__{recipient: String.t()}

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"to_adrecipientdress" => recipient}) when is_binary(recipient) do
    {:ok, %__MODULE__{recipient: recipient}}
  end

  def new(_), do: {:error, :invalid_attrs}
end
