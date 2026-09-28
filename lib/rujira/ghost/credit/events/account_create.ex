defmodule Rujira.Ghost.Credit.Events.AccountCreate do
  @moduledoc "A credit account creation (`wasm-rujira-ghost-credit/account.create`)."

  defstruct owner: nil, address: nil

  @type t :: %__MODULE__{owner: String.t(), address: String.t()}

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"owner" => owner, "address" => address})
      when is_binary(owner) and is_binary(address) do
    {:ok, %__MODULE__{owner: owner, address: address}}
  end

  def new(_), do: {:error, :invalid_attrs}
end
