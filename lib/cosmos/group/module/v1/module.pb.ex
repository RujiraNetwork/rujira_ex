defmodule Cosmos.Group.Module.V1.Module do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:max_execution_period, 1,
    type: Google.Protobuf.Duration,
    json_name: "maxExecutionPeriod",
    deprecated: false
  )

  field(:max_metadata_len, 2, type: :uint64, json_name: "maxMetadataLen")
end
