defmodule Thorchain.Types.VolumeBucket do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asset, 1, type: Thorchain.Common.Asset, deprecated: false)
  field(:index, 2, type: :int64)
  field(:amount_rune, 3, type: :string, json_name: "amountRune", deprecated: false)
  field(:amount_asset, 4, type: :string, json_name: "amountAsset", deprecated: false)
end
