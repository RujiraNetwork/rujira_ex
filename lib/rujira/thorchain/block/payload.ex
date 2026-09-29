defmodule Rujira.Thorchain.Block.Payload do
  @moduledoc """
  The CosmWasm `msg` payload of a wasm message, as a map.

  thornode renders a message's `msg` as the JSON object it is, so a payload
  arrives already decoded. A payload that arrives base64-encoded instead -
  protobuf's own JSON rendering of a `bytes` field - is decoded and parsed, so
  either form reaches a caller as the same map.

  An absent payload is `nil`. Anything that is neither is `{:error,
  :invalid_msg}`, which makes its message a generic one rather than failing the
  block.
  """

  @spec decode(term()) :: {:ok, map() | nil} | {:error, :invalid_msg}
  def decode(nil), do: {:ok, nil}
  def decode(%{} = msg), do: {:ok, msg}

  def decode(msg) when is_binary(msg) do
    with {:ok, json} <- Rujira.String.decode_base64(msg),
         {:ok, %{} = decoded} <- JSON.decode(json) do
      {:ok, decoded}
    else
      _ -> {:error, :invalid_msg}
    end
  end

  def decode(_msg), do: {:error, :invalid_msg}
end
