defmodule Rujira.Ghost.Credit.Events.AccountMsgSetPreferenceMsgs do
  @moduledoc """
  An owner replacing their liquidation route preferences
  (`wasm-rujira-ghost-credit/account.msg/set_preference_msgs`).

  The contract emits no attributes for it - the new route is in the message, not
  in the event - so the struct carries none.
  """

  defstruct []

  @type t :: %__MODULE__{}

  @spec new(map()) :: {:ok, t()}
  def new(%{}), do: {:ok, %__MODULE__{}}
end
