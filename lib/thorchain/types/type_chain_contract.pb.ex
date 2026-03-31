defmodule Thorchain.Types.ChainContract do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:chain, 1, type: :string, deprecated: false)
  field(:router, 2, type: :string, deprecated: false)
end
