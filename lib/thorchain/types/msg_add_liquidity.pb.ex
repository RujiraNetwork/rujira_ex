defmodule Thorchain.Types.MsgAddLiquidity do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx, 1, type: Thorchain.Common.Tx, deprecated: false)
  field(:asset, 2, type: Thorchain.Common.Asset, deprecated: false)
  field(:asset_amount, 3, type: :string, json_name: "assetAmount", deprecated: false)
  field(:rune_amount, 4, type: :string, json_name: "runeAmount", deprecated: false)
  field(:rune_address, 5, type: :string, json_name: "runeAddress", deprecated: false)
  field(:asset_address, 6, type: :string, json_name: "assetAddress", deprecated: false)
  field(:affiliate_address, 7, type: :string, json_name: "affiliateAddress", deprecated: false)

  field(:affiliate_basis_points, 8,
    type: :string,
    json_name: "affiliateBasisPoints",
    deprecated: false
  )

  field(:signer, 9, type: :bytes, deprecated: false)
end
