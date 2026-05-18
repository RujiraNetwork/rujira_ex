defmodule Thorchain.Types.MsgNoOp do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:observed_tx, 1,
    type: Thorchain.Common.ObservedTx,
    json_name: "observedTx",
    deprecated: false
  )

  field(:signer, 2, type: :bytes, deprecated: false)
  field(:action, 3, type: :string)
end
