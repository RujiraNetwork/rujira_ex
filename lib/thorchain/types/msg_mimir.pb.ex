defmodule Thorchain.Types.MsgMimir do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:key, 1, type: :string)
  field(:value, 2, type: :int64)
  field(:signer, 3, type: :bytes, deprecated: false)
end
