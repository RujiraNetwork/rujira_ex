defmodule Thorchain.Types.QueryNetworkRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
end

defmodule Thorchain.Types.QueryNetworkResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:bond_reward_rune, 1, type: :string, json_name: "bondRewardRune", deprecated: false)
  field(:total_bond_units, 2, type: :string, json_name: "totalBondUnits", deprecated: false)

  field(:available_pools_rune, 15,
    type: :string,
    json_name: "availablePoolsRune",
    deprecated: false
  )

  field(:vaults_liquidity_rune, 16,
    type: :string,
    json_name: "vaultsLiquidityRune",
    deprecated: false
  )

  field(:effective_security_bond, 3,
    type: :string,
    json_name: "effectiveSecurityBond",
    deprecated: false
  )

  field(:total_reserve, 4, type: :string, json_name: "totalReserve", deprecated: false)
  field(:vaults_migrating, 5, type: :bool, json_name: "vaultsMigrating", deprecated: false)
  field(:gas_spent_rune, 6, type: :string, json_name: "gasSpentRune", deprecated: false)
  field(:gas_withheld_rune, 7, type: :string, json_name: "gasWithheldRune", deprecated: false)
  field(:outbound_fee_multiplier, 8, type: :string, json_name: "outboundFeeMultiplier")

  field(:native_outbound_fee_rune, 9,
    type: :string,
    json_name: "nativeOutboundFeeRune",
    deprecated: false
  )

  field(:native_tx_fee_rune, 10, type: :string, json_name: "nativeTxFeeRune", deprecated: false)

  field(:tns_register_fee_rune, 11,
    type: :string,
    json_name: "tnsRegisterFeeRune",
    deprecated: false
  )

  field(:tns_fee_per_block_rune, 12,
    type: :string,
    json_name: "tnsFeePerBlockRune",
    deprecated: false
  )

  field(:rune_price_in_tor, 13, type: :string, json_name: "runePriceInTor", deprecated: false)
  field(:tor_price_in_rune, 14, type: :string, json_name: "torPriceInRune", deprecated: false)
  field(:tor_price_halted, 17, type: :bool, json_name: "torPriceHalted", deprecated: false)
end
