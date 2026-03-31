defmodule Thorchain.Types.RagnarokWithdrawPosition do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:number, 1, type: :int64)
  field(:pool, 2, type: Thorchain.Common.Asset, deprecated: false)
end
