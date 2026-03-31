defmodule Thorchain.Types.Jail do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:node_address, 1, type: :bytes, json_name: "nodeAddress", deprecated: false)
  field(:release_height, 2, type: :int64, json_name: "releaseHeight")
  field(:reason, 3, type: :string)
end
