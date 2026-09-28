defmodule Rujira.Ghost.Credit.Events.AccountMsgExecute do
  @moduledoc """
  A credit account executing a message on another contract
  (`wasm-rujira-ghost-credit/account.msg/execute`).

  `msg` is the payload base64-decoded - the raw bytes, not parsed JSON.

  The event also carries a `funds` attribute, which this struct drops: it is a
  `NativeBalance` rendered with no delimiter between coins, so a multi-coin value
  cannot be split back apart. A parsed field would be a guess, not chain data.
  Upstream is fixing the rendering.
  """

  defstruct contract: nil, msg: nil

  @type t :: %__MODULE__{contract: String.t(), msg: binary()}

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"contract_addr" => contract, "msg" => msg}) when is_binary(contract) do
    with {:ok, msg} <- decode_msg(msg) do
      {:ok, %__MODULE__{contract: contract, msg: msg}}
    end
  end

  def new(_), do: {:error, :invalid_attrs}

  defp decode_msg(msg) when is_binary(msg) do
    case Base.decode64(msg) do
      {:ok, decoded} -> {:ok, decoded}
      :error -> {:error, :invalid_msg}
    end
  end

  defp decode_msg(_), do: {:error, :invalid_msg}
end
