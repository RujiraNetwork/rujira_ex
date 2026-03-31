defmodule Cosmos.Evidence.V1beta1.GenesisState do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:evidence, 1, repeated: true, type: Google.Protobuf.Any)
end
