defmodule Thorchain.Types.SwapType do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:market, 0)
  field(:limit, 1)
end

defmodule Thorchain.Types.SwapVersion do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:v1, 0)
  field(:v2, 1)
end

defmodule Thorchain.Types.SwapState do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:interval, 1, type: :uint64)
  field(:quantity, 2, type: :uint64)
  field(:ttl, 3, type: :uint64)
  field(:count, 4, type: :uint64)
  field(:last_height, 5, type: :int64, json_name: "lastHeight")
  field(:deposit, 6, type: :string, deprecated: false)
  field(:withdrawn, 7, type: :string, deprecated: false)
  field(:in, 8, type: :string, deprecated: false)
  field(:out, 9, type: :string, deprecated: false)
  field(:failed_swaps, 10, repeated: true, type: :uint64, json_name: "failedSwaps")
  field(:failed_swap_reasons, 11, repeated: true, type: :string, json_name: "failedSwapReasons")
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

  field(:swap_type, 11, type: Thorchain.Types.SwapType, json_name: "swapType", enum: true)
  field(:stream_quantity, 12, type: :uint64, json_name: "streamQuantity")
  field(:stream_interval, 13, type: :uint64, json_name: "streamInterval")
  field(:initial_block_height, 14, type: :int64, json_name: "initialBlockHeight")
  field(:state, 15, type: Thorchain.Types.SwapState)
  field(:version, 16, type: Thorchain.Types.SwapVersion, enum: true)
  field(:index, 17, type: :uint32)
end
