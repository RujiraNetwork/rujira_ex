defmodule Cosmos.Gov.Module.V1.Module do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:max_metadata_len, 1, type: :uint64, json_name: "maxMetadataLen")
  field(:authority, 2, type: :string)
end
