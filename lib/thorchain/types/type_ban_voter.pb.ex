defmodule Thorchain.Types.BanVoter do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:node_address, 1, type: :bytes, json_name: "nodeAddress", deprecated: false)
  field(:block_height, 2, type: :int64, json_name: "blockHeight")
  field(:signers, 3, repeated: true, type: :string)
end
