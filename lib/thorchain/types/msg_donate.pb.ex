defmodule Thorchain.Types.MsgDonate do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asset, 1, type: Thorchain.Common.Asset, deprecated: false)
  field(:asset_amount, 2, type: :string, json_name: "assetAmount", deprecated: false)
  field(:rune_amount, 3, type: :string, json_name: "runeAmount", deprecated: false)
  field(:tx, 4, type: Thorchain.Common.Tx, deprecated: false)
  field(:signer, 5, type: :bytes, deprecated: false)
end
