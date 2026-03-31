defmodule Thorchain.Types.StreamingSwap do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx_id, 1, type: :string, json_name: "txId", deprecated: false)
  field(:interval, 2, type: :uint64)
  field(:quantity, 3, type: :uint64)
  field(:count, 4, type: :uint64)
  field(:last_height, 5, type: :int64, json_name: "lastHeight")
  field(:trade_target, 6, type: :string, json_name: "tradeTarget", deprecated: false)
  field(:deposit, 7, type: :string, deprecated: false)
  field(:in, 8, type: :string, deprecated: false)
  field(:out, 9, type: :string, deprecated: false)
  field(:failed_swaps, 10, repeated: true, type: :uint64, json_name: "failedSwaps")
  field(:failed_swap_reasons, 11, repeated: true, type: :string, json_name: "failedSwapReasons")
end
