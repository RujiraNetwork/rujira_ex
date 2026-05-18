defmodule Thorchain.Types.QueryLimitSwapsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
  field(:offset, 2, type: :uint64)
  field(:limit, 3, type: :uint64)
  field(:source_asset, 4, type: :string, json_name: "sourceAsset")
  field(:target_asset, 5, type: :string, json_name: "targetAsset")
  field(:sender, 6, type: :string)
  field(:sort_by, 7, type: :string, json_name: "sortBy")
  field(:sort_order, 8, type: :string, json_name: "sortOrder")
end

defmodule Thorchain.Types.LimitSwapWithDetails do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:swap, 1, type: Thorchain.Types.MsgSwap)
  field(:ratio, 2, type: :string)
  field(:blocks_since_created, 3, type: :int64, json_name: "blocksSinceCreated")
  field(:time_to_expiry_blocks, 4, type: :int64, json_name: "timeToExpiryBlocks")
  field(:created_timestamp, 5, type: :int64, json_name: "createdTimestamp")
end

defmodule Thorchain.Types.PaginationMeta do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:offset, 1, type: :uint64)
  field(:limit, 2, type: :uint64)
  field(:total, 3, type: :uint64)
  field(:has_next, 4, type: :bool, json_name: "hasNext")
  field(:has_prev, 5, type: :bool, json_name: "hasPrev")
end

defmodule Thorchain.Types.QueryLimitSwapsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:limit_swaps, 1,
    repeated: true,
    type: Thorchain.Types.LimitSwapWithDetails,
    json_name: "limitSwaps"
  )

  field(:pagination, 2, type: Thorchain.Types.PaginationMeta)
end
