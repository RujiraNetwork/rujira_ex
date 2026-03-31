defmodule Thorchain.Types.MsgRagnarok do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx, 1, type: Thorchain.Types.ObservedTx, deprecated: false)
  field(:block_height, 2, type: :int64, json_name: "blockHeight")
  field(:signer, 3, type: :bytes, deprecated: false)
end
