defmodule Thorchain.Types.MsgOutboundTx do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx, 1, type: Thorchain.Types.ObservedTx, deprecated: false)
  field(:in_tx_id, 2, type: :string, json_name: "inTxId", deprecated: false)
  field(:signer, 3, type: :bytes, deprecated: false)
end
