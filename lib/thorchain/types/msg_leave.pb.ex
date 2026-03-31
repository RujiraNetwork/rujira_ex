defmodule Thorchain.Types.MsgLeave do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx, 1, type: Thorchain.Common.Tx, deprecated: false)
  field(:node_address, 2, type: :bytes, json_name: "nodeAddress", deprecated: false)
  field(:signer, 3, type: :bytes, deprecated: false)
end
