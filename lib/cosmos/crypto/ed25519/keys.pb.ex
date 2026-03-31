defmodule Cosmos.Crypto.Ed25519.PubKey do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:key, 1, type: :bytes, deprecated: false)
end

defmodule Cosmos.Crypto.Ed25519.PrivKey do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:key, 1, type: :bytes, deprecated: false)
end
