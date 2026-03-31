defmodule Cosmos.Feegrant.V1beta1.GenesisState do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:allowances, 1, repeated: true, type: Cosmos.Feegrant.V1beta1.Grant, deprecated: false)
end
