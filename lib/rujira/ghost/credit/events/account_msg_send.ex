defmodule Rujira.Ghost.Credit.Events.AccountMsgSend do
  @moduledoc """
  A credit account sending funds out (`wasm-rujira-ghost-credit/account.msg/send`).

  The event also carries a `funds` attribute, which this struct drops: it is a
  `NativeBalance` rendered with no delimiter between coins, so a multi-coin value
  cannot be split back apart. A parsed field would be a guess, not chain data.
  Upstream is fixing the rendering.
  """

  defstruct to_address: nil

  @type t :: %__MODULE__{to_address: String.t()}

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"to_address" => to_address}) when is_binary(to_address) do
    {:ok, %__MODULE__{to_address: to_address}}
  end

  def new(_), do: {:error, :invalid_attrs}
end
