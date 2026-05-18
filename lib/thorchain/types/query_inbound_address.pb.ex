defmodule Thorchain.Types.QueryInboundAddressResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:chain, 1, type: :string)
  field(:pub_key, 2, type: :string, json_name: "pubKey")
  field(:address, 3, type: :string)
  field(:router, 4, type: :string)
  field(:halted, 5, type: :bool, deprecated: false)

  field(:global_trading_paused, 6,
    type: :bool,
    json_name: "globalTradingPaused",
    deprecated: false
  )

  field(:chain_trading_paused, 7, type: :bool, json_name: "chainTradingPaused", deprecated: false)

  field(:chain_lp_actions_paused, 8,
    type: :bool,
    json_name: "chainLpActionsPaused",
    deprecated: false
  )

  field(:observed_fee_rate, 14, type: :string, json_name: "observedFeeRate")
  field(:gas_rate, 9, type: :string, json_name: "gasRate")
  field(:gas_rate_units, 10, type: :string, json_name: "gasRateUnits")
  field(:outbound_tx_size, 11, type: :string, json_name: "outboundTxSize")
  field(:outbound_fee, 12, type: :string, json_name: "outboundFee")
  field(:dust_threshold, 13, type: :string, json_name: "dustThreshold")
end

defmodule Thorchain.Types.QueryInboundAddressesRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
end

defmodule Thorchain.Types.QueryInboundAddressesResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:inbound_addresses, 1,
    repeated: true,
    type: Thorchain.Types.QueryInboundAddressResponse,
    json_name: "inboundAddresses"
  )
end
