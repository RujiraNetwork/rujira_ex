defmodule Thorchain.Types.MsgReferenceMemo do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asset, 1, type: Thorchain.Common.Asset, deprecated: false)
  field(:memo, 2, type: :string)
  field(:signer, 3, type: :bytes, deprecated: false)
end
