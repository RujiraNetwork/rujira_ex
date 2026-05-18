defmodule Thorchain.Types.QueryQuoteSwapRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:from_asset, 1, type: :string, json_name: "fromAsset")
  field(:to_asset, 2, type: :string, json_name: "toAsset")
  field(:amount, 3, type: :string)
  field(:streaming_interval, 4, type: :string, json_name: "streamingInterval")
  field(:streaming_quantity, 5, type: :string, json_name: "streamingQuantity")
  field(:destination, 6, type: :string)
  field(:tolerance_bps, 7, type: :string, json_name: "toleranceBps")
  field(:refund_address, 8, type: :string, json_name: "refundAddress")
  field(:affiliate, 9, type: :string)
  field(:affiliate_bps, 10, type: :string, json_name: "affiliateBps")
  field(:height, 11, type: :string)
  field(:liquidity_tolerance_bps, 12, type: :string, json_name: "liquidityToleranceBps")
  field(:extended, 13, type: :bool)
end

defmodule Thorchain.Types.QueryQuoteSwapResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:inbound_address, 1, type: :string, json_name: "inboundAddress")
  field(:inbound_confirmation_blocks, 2, type: :int64, json_name: "inboundConfirmationBlocks")
  field(:inbound_confirmation_seconds, 3, type: :int64, json_name: "inboundConfirmationSeconds")

  field(:outbound_delay_blocks, 4,
    type: :int64,
    json_name: "outboundDelayBlocks",
    deprecated: false
  )

  field(:outbound_delay_seconds, 5,
    type: :int64,
    json_name: "outboundDelaySeconds",
    deprecated: false
  )

  field(:fees, 6, type: Thorchain.Types.QuoteFees, deprecated: false)
  field(:router, 7, type: :string)
  field(:expiry, 8, type: :int64, deprecated: false)
  field(:warning, 9, type: :string, deprecated: false)
  field(:notes, 10, type: :string, deprecated: false)
  field(:dust_threshold, 11, type: :string, json_name: "dustThreshold")
  field(:recommended_min_amount_in, 12, type: :string, json_name: "recommendedMinAmountIn")
  field(:recommended_gas_rate, 13, type: :string, json_name: "recommendedGasRate")
  field(:gas_rate_units, 14, type: :string, json_name: "gasRateUnits")
  field(:memo, 15, type: :string)

  field(:expected_amount_out, 16,
    type: :string,
    json_name: "expectedAmountOut",
    deprecated: false
  )

  field(:max_streaming_quantity, 17,
    type: :int64,
    json_name: "maxStreamingQuantity",
    deprecated: false
  )

  field(:streaming_swap_blocks, 18,
    type: :int64,
    json_name: "streamingSwapBlocks",
    deprecated: false
  )

  field(:streaming_swap_seconds, 19, type: :int64, json_name: "streamingSwapSeconds")
  field(:total_swap_seconds, 20, type: :int64, json_name: "totalSwapSeconds")
  field(:vout, 21, repeated: true, type: Thorchain.Types.Vout)
end

defmodule Thorchain.Types.QuoteFees do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asset, 1, type: :string, deprecated: false)
  field(:affiliate, 2, type: :string)
  field(:outbound, 3, type: :string)
  field(:liquidity, 4, type: :string, deprecated: false)
  field(:total, 5, type: :string, deprecated: false)
  field(:slippage_bps, 6, type: :int64, json_name: "slippageBps", deprecated: false)
  field(:total_bps, 7, type: :int64, json_name: "totalBps", deprecated: false)
end

defmodule Thorchain.Types.Vout do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:type, 1, type: :string, deprecated: false)
  field(:data, 2, type: :string, deprecated: false)
  field(:amount, 3, type: :int64, deprecated: false)
end

defmodule Thorchain.Types.QueryQuoteLimitRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:from_asset, 1, type: :string, json_name: "fromAsset", deprecated: false)
  field(:to_asset, 2, type: :string, json_name: "toAsset", deprecated: false)
  field(:amount, 3, type: :string, deprecated: false)
  field(:destination, 4, type: :string, deprecated: false)
  field(:target_out, 5, type: :string, json_name: "targetOut", deprecated: false)
  field(:custom_ttl, 6, type: :string, json_name: "customTtl", deprecated: false)
  field(:streaming_quantity, 7, type: :string, json_name: "streamingQuantity", deprecated: false)
  field(:affiliate, 8, type: :string, deprecated: false)
  field(:affiliate_bps, 9, type: :string, json_name: "affiliateBps", deprecated: false)
  field(:refund_address, 10, type: :string, json_name: "refundAddress", deprecated: false)
end

defmodule Thorchain.Types.QueryQuoteLimitResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:expected_amount_out, 1, type: :string, json_name: "expectedAmountOut", deprecated: false)
  field(:fees, 2, type: Thorchain.Types.QuoteFees, deprecated: false)
  field(:inbound_address, 3, type: :string, json_name: "inboundAddress", deprecated: false)
  field(:memo, 4, type: :string, deprecated: false)
  field(:order_expiry_block, 5, type: :int64, json_name: "orderExpiryBlock", deprecated: false)

  field(:order_expiry_timestamp, 6,
    type: :int64,
    json_name: "orderExpiryTimestamp",
    deprecated: false
  )

  field(:recommended_min_amount_in, 7,
    type: :string,
    json_name: "recommendedMinAmountIn",
    deprecated: false
  )

  field(:router, 8, type: :string, deprecated: false)
  field(:dust_threshold, 9, type: :string, json_name: "dustThreshold", deprecated: false)
  field(:notes, 10, type: :string, deprecated: false)
  field(:recommended_gas_rate, 11, type: :string, json_name: "recommendedGasRate")
  field(:gas_rate_units, 12, type: :string, json_name: "gasRateUnits")
end
