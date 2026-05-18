defmodule Thorchain.Types.ThornameAlias do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:chain, 1, type: :string, deprecated: false)
  field(:address, 2, type: :string, deprecated: false)
end

defmodule Thorchain.Types.THORName do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:name, 1, type: :string)
  field(:expire_block_height, 2, type: :int64, json_name: "expireBlockHeight")
  field(:owner, 3, type: :bytes, deprecated: false)

  field(:preferred_asset, 4,
    type: Thorchain.Common.Asset,
    json_name: "preferredAsset",
    deprecated: false
  )

  field(:aliases, 5, repeated: true, type: Thorchain.Types.ThornameAlias, deprecated: false)

  field(:preferred_asset_outbound_fee_multiplier, 6,
    type: :int64,
    json_name: "preferredAssetOutboundFeeMultiplier"
  )
end
