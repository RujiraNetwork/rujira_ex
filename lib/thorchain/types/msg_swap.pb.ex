defmodule Thorchain.Types.OrderType do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:market, 0)
  field(:limit, 1)
end

defmodule Thorchain.Types.MsgSwap do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx, 1, type: Thorchain.Common.Tx, deprecated: false)

  field(:target_asset, 2,
    type: Thorchain.Common.Asset,
    json_name: "targetAsset",
    deprecated: false
  )

  field(:destination, 3, type: :string, deprecated: false)
  field(:trade_target, 4, type: :string, json_name: "tradeTarget", deprecated: false)
  field(:affiliate_address, 5, type: :string, json_name: "affiliateAddress", deprecated: false)

  field(:affiliate_basis_points, 6,
    type: :string,
    json_name: "affiliateBasisPoints",
    deprecated: false
  )

  field(:signer, 7, type: :bytes, deprecated: false)
  field(:aggregator, 8, type: :string)
  field(:aggregator_target_address, 9, type: :string, json_name: "aggregatorTargetAddress")

  field(:aggregator_target_limit, 10,
    type: :string,
    json_name: "aggregatorTargetLimit",
    deprecated: false
  )

  field(:order_type, 11, type: Thorchain.Types.OrderType, json_name: "orderType", enum: true)
  field(:stream_quantity, 12, type: :uint64, json_name: "streamQuantity")
  field(:stream_interval, 13, type: :uint64, json_name: "streamInterval")
end
