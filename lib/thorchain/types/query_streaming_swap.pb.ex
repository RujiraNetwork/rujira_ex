defmodule Thorchain.Types.QueryStreamingSwapRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx_id, 1, type: :string, json_name: "txId")
  field(:height, 2, type: :string)
end

defmodule Thorchain.Types.QueryStreamingSwapResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx_id, 1, type: :string, json_name: "txId")
  field(:interval, 2, type: :int64)
  field(:quantity, 3, type: :int64)
  field(:count, 4, type: :int64)
  field(:last_height, 5, type: :int64, json_name: "lastHeight")
  field(:trade_target, 6, type: :string, json_name: "tradeTarget", deprecated: false)
  field(:source_asset, 7, type: :string, json_name: "sourceAsset")
  field(:target_asset, 8, type: :string, json_name: "targetAsset")
  field(:destination, 9, type: :string)
  field(:deposit, 10, type: :string, deprecated: false)
  field(:in, 11, type: :string, deprecated: false)
  field(:out, 12, type: :string, deprecated: false)
  field(:failed_swaps, 13, repeated: true, type: :int64, json_name: "failedSwaps")
  field(:failed_swap_reasons, 14, repeated: true, type: :string, json_name: "failedSwapReasons")
end

defmodule Thorchain.Types.QueryStreamingSwapsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
end

defmodule Thorchain.Types.QueryStreamingSwapsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:streaming_swaps, 1,
    repeated: true,
    type: Thorchain.Types.QueryStreamingSwapResponse,
    json_name: "streamingSwaps"
  )
end
