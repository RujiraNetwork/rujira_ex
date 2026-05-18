defmodule Thorchain.Types.Volume do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asset, 1, type: Thorchain.Common.Asset, deprecated: false)
  field(:total_rune, 2, type: :string, json_name: "totalRune", deprecated: false)
  field(:total_asset, 3, type: :string, json_name: "totalAsset", deprecated: false)
  field(:change_rune, 4, type: :string, json_name: "changeRune", deprecated: false)
  field(:change_asset, 5, type: :string, json_name: "changeAsset", deprecated: false)
  field(:last_bucket, 6, type: :int64, json_name: "lastBucket")
end
