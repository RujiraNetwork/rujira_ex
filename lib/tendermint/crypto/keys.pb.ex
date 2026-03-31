defmodule Tendermint.Crypto.PublicKey do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  oneof(:sum, 0)

  field(:ed25519, 1, type: :bytes, oneof: 0)
  field(:secp256k1, 2, type: :bytes, oneof: 0)
end
