defmodule Cosmos.Auth.V1beta1.GenesisState do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:params, 1, type: Cosmos.Auth.V1beta1.Params, deprecated: false)
  field(:accounts, 2, repeated: true, type: Google.Protobuf.Any)
end
