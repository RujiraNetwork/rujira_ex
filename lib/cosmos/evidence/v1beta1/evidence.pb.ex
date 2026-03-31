defmodule Cosmos.Evidence.V1beta1.Equivocation do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :int64)
  field(:time, 2, type: Google.Protobuf.Timestamp, deprecated: false)
  field(:power, 3, type: :int64)
  field(:consensus_address, 4, type: :string, json_name: "consensusAddress", deprecated: false)
end
