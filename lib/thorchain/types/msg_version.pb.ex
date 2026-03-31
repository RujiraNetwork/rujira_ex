defmodule Thorchain.Types.MsgSetVersion do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:version, 1, type: :string)
  field(:signer, 2, type: :bytes, deprecated: false)
end
