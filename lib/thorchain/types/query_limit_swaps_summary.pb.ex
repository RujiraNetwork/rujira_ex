defmodule Thorchain.Types.QueryLimitSwapsSummaryRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
  field(:source_asset, 2, type: :string, json_name: "sourceAsset")
  field(:target_asset, 3, type: :string, json_name: "targetAsset")
end

defmodule Thorchain.Types.AssetPairSummary do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:source_asset, 1, type: :string, json_name: "sourceAsset")
  field(:target_asset, 2, type: :string, json_name: "targetAsset")
  field(:count, 3, type: :uint64)
  field(:total_value_usd, 4, type: :string, json_name: "totalValueUsd")
end

defmodule Thorchain.Types.QueryLimitSwapsSummaryResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:total_limit_swaps, 1, type: :uint64, json_name: "totalLimitSwaps")
  field(:total_value_usd, 2, type: :string, json_name: "totalValueUsd")

  field(:asset_pairs, 3,
    repeated: true,
    type: Thorchain.Types.AssetPairSummary,
    json_name: "assetPairs"
  )

  field(:oldest_swap_blocks, 4, type: :int64, json_name: "oldestSwapBlocks")
  field(:average_age_blocks, 5, type: :int64, json_name: "averageAgeBlocks")
end
