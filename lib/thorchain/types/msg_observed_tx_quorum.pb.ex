defmodule Thorchain.Types.MsgObservedTxQuorum do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:quoTx, 1, type: Thorchain.Common.QuorumTx)
  field(:signer, 2, type: :bytes, deprecated: false)
end
