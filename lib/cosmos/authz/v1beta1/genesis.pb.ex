defmodule Cosmos.Authz.V1beta1.GenesisState do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:authorization, 1,
    repeated: true,
    type: Cosmos.Authz.V1beta1.GrantAuthorization,
    deprecated: false
  )
end
