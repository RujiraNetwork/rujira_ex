defmodule Thorchain.Types.MsgMaint do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:node_address, 1, type: :bytes, json_name: "nodeAddress", deprecated: false)
  field(:signer, 2, type: :bytes, deprecated: false)
end
