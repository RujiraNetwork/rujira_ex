defmodule Thorchain.Types.PoolStatus do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:UnknownPoolStatus, 0)
  field(:Available, 1)
  field(:Staged, 2)
  field(:Suspended, 3)
end

defmodule Thorchain.Types.Pool do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:balance_rune, 1, type: :string, json_name: "balanceRune", deprecated: false)
  field(:balance_asset, 2, type: :string, json_name: "balanceAsset", deprecated: false)
  field(:asset, 3, type: Thorchain.Common.Asset, deprecated: false)
  field(:LP_units, 4, type: :string, json_name: "LPUnits", deprecated: false)
  field(:status, 5, type: Thorchain.Types.PoolStatus, enum: true)
  field(:status_since, 10, type: :int64, json_name: "statusSince")
  field(:decimals, 6, type: :int64)
  field(:synth_units, 7, type: :string, json_name: "synthUnits", deprecated: false)

  field(:pending_inbound_rune, 8,
    type: :string,
    json_name: "pendingInboundRune",
    deprecated: false
  )

  field(:pending_inbound_asset, 9,
    type: :string,
    json_name: "pendingInboundAsset",
    deprecated: false
  )
end
