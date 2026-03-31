defmodule Thorchain.Types.MsgNodePauseChain do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:value, 1, type: :int64)
  field(:signer, 2, type: :bytes, deprecated: false)
end
