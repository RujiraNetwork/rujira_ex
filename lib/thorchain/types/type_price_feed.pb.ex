defmodule Thorchain.Types.PriceFeed do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:node, 1, type: :bytes, deprecated: false)
  field(:rates, 2, repeated: true, type: Thorchain.Common.OraclePrice)
end
