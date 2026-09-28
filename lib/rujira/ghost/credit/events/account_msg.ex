defmodule Rujira.Ghost.Credit.Events.AccountMsg do
  @moduledoc """
  An owner executing messages on their credit account
  (`wasm-rujira-ghost-credit/account.msg`).

  Each message in the batch emits its own `account.msg/*` event.
  """

  defstruct owner: nil, address: nil

  @type t :: %__MODULE__{owner: String.t(), address: String.t()}

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"owner" => owner, "address" => address})
      when is_binary(owner) and is_binary(address) do
    {:ok, %__MODULE__{owner: owner, address: address}}
  end

  def new(_), do: {:error, :invalid_attrs}
end
