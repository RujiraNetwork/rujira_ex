defmodule Thorchain.Types.MsgManageTHORName do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:name, 1, type: :string)
  field(:chain, 2, type: :string, deprecated: false)
  field(:address, 3, type: :string, deprecated: false)
  field(:coin, 4, type: Thorchain.Common.Coin, deprecated: false)
  field(:expire_block_height, 5, type: :int64, json_name: "expireBlockHeight")

  field(:preferred_asset, 6,
    type: Thorchain.Common.Asset,
    json_name: "preferredAsset",
    deprecated: false
  )

  field(:owner, 7, type: :bytes, deprecated: false)
  field(:signer, 8, type: :bytes, deprecated: false)

  field(:preferred_asset_outbound_fee_multiplier, 9,
    type: :int64,
    json_name: "preferredAssetOutboundFeeMultiplier"
  )
end
