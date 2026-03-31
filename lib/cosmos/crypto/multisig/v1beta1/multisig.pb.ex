defmodule Cosmos.Crypto.Multisig.V1beta1.MultiSignature do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:signatures, 1, repeated: true, type: :bytes)
end

defmodule Cosmos.Crypto.Multisig.V1beta1.CompactBitArray do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:extra_bits_stored, 1, type: :uint32, json_name: "extraBitsStored")
  field(:elems, 2, type: :bytes)
end
