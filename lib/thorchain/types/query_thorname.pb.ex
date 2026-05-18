defmodule Thorchain.Types.QueryThornameRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:name, 1, type: :string)
  field(:height, 2, type: :string)
end

defmodule Thorchain.Types.QueryThornameResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:name, 1, type: :string)
  field(:expire_block_height, 2, type: :int64, json_name: "expireBlockHeight")
  field(:owner, 3, type: :string)
  field(:preferred_asset, 4, type: :string, json_name: "preferredAsset", deprecated: false)

  field(:preferred_asset_swap_threshold_rune, 7,
    type: :string,
    json_name: "preferredAssetSwapThresholdRune"
  )

  field(:preferred_asset_outbound_fee_multiplier, 8,
    type: :int64,
    json_name: "preferredAssetOutboundFeeMultiplier"
  )

  field(:affiliate_collector_rune, 5, type: :string, json_name: "affiliateCollectorRune")
  field(:aliases, 6, repeated: true, type: Thorchain.Types.ThornameAlias, deprecated: false)
end

defmodule Thorchain.Types.ThornameAlias do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:chain, 1, type: :string)
  field(:address, 2, type: :string)
end
