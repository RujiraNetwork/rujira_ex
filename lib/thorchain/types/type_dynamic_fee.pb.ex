defmodule Thorchain.Types.DynamicFeeEpochRecord do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:epoch, 1, type: :uint64)
  field(:volume_tor, 2, type: :string, json_name: "volumeTor", deprecated: false)
  field(:fees_tor, 3, type: :string, json_name: "feesTor", deprecated: false)
  field(:bps_at_close, 4, type: :uint64, json_name: "bpsAtClose")
end

defmodule Thorchain.Types.DynamicFeeRecord do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:thorname, 1, type: :string)
  field(:pair_asset_a, 2, type: :string, json_name: "pairAssetA")
  field(:pair_asset_b, 3, type: :string, json_name: "pairAssetB")
  field(:dynamic_bps, 4, type: :uint64, json_name: "dynamicBps")
  field(:last_active_epoch, 5, type: :uint64, json_name: "lastActiveEpoch")

  field(:history, 6,
    repeated: true,
    type: Thorchain.Types.DynamicFeeEpochRecord,
    deprecated: false
  )
end

defmodule Thorchain.Types.DynamicFeeAccumulator do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:thorname, 1, type: :string)
  field(:pair_asset_a, 2, type: :string, json_name: "pairAssetA")
  field(:pair_asset_b, 3, type: :string, json_name: "pairAssetB")
  field(:volume_tor, 4, type: :string, json_name: "volumeTor", deprecated: false)
  field(:fees_tor, 5, type: :string, json_name: "feesTor", deprecated: false)
end
