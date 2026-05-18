defmodule Thorchain.Types.MsgObservedTxIn do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:txs, 1, repeated: true, type: Thorchain.Common.ObservedTx, deprecated: false)
  field(:signer, 2, type: :bytes, deprecated: false)
end
