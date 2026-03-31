defmodule Tendermint.Libs.Bits.BitArray do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:bits, 1, type: :int64)
  field(:elems, 2, repeated: true, type: :uint64)
end
