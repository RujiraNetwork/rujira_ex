defmodule Rujira.Ghost.Credit.LiquidateMsg.Execute do
  @moduledoc """
  A liquidation step that executes a message on another contract
  (`LiquidateMsg::Execute`), typically the swap that turns collateral into the
  debt asset.

  `msg` is the contract payload base64-decoded - the raw bytes, not parsed JSON.
  """

  alias Rujira.Coin

  # --- Struct ---

  defstruct contract: nil, msg: nil, funds: []

  @type t :: %__MODULE__{
          contract: String.t() | nil,
          msg: binary() | nil,
          funds: [Coin.t()]
        }

  # --- Construction ---

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"contract_addr" => contract, "msg" => msg, "funds" => funds})
      when is_binary(contract) and is_list(funds) do
    with {:ok, msg} <- decode_msg(msg),
         {:ok, funds} <- Rujira.Enum.reduce_while_ok(funds, [], &coin/1) do
      {:ok, %__MODULE__{contract: contract, msg: msg, funds: funds}}
    end
  end

  def new(_), do: {:error, :invalid_attrs}

  # --- Private ---

  defp decode_msg(msg) when is_binary(msg) do
    case Base.decode64(msg) do
      {:ok, decoded} -> {:ok, decoded}
      :error -> {:error, :invalid_msg}
    end
  end

  defp decode_msg(_), do: {:error, :invalid_msg}

  defp coin(%{"denom" => denom, "amount" => amount})
       when is_binary(denom) and is_binary(amount),
       do: Coin.new(denom, amount)

  defp coin(_), do: {:error, :invalid_attrs}
end
