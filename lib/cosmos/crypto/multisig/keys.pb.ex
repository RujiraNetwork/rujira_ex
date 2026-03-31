defmodule Cosmos.Crypto.Multisig.LegacyAminoPubKey do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:threshold, 1, type: :uint32)

  field(:public_keys, 2,
    repeated: true,
    type: Google.Protobuf.Any,
    json_name: "publicKeys",
    deprecated: false
  )
end
