defmodule Thorchain.Thorchain.LastChainHeight do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:chain, 1, type: :string)
  field(:height, 2, type: :int64)
end

defmodule Thorchain.Thorchain.Mimir do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:key, 1, type: :string)
  field(:value, 2, type: :int64)
end

defmodule Thorchain.Thorchain.GenesisState do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pools, 1, repeated: true, type: Thorchain.Types.Pool, deprecated: false)

  field(:liquidity_providers, 2,
    repeated: true,
    type: Thorchain.Types.LiquidityProvider,
    json_name: "liquidityProviders",
    deprecated: false
  )

  field(:observed_tx_in_voters, 3,
    repeated: true,
    type: Thorchain.Types.ObservedTxVoter,
    json_name: "observedTxInVoters",
    deprecated: false
  )

  field(:observed_tx_out_voters, 4,
    repeated: true,
    type: Thorchain.Types.ObservedTxVoter,
    json_name: "observedTxOutVoters",
    deprecated: false
  )

  field(:tx_outs, 5,
    repeated: true,
    type: Thorchain.Types.TxOut,
    json_name: "txOuts",
    deprecated: false
  )

  field(:node_accounts, 6,
    repeated: true,
    type: Thorchain.Types.NodeAccount,
    json_name: "nodeAccounts",
    deprecated: false
  )

  field(:vaults, 7, repeated: true, type: Thorchain.Types.Vault, deprecated: false)
  field(:reserve, 8, type: :uint64)
  field(:last_signed_height, 10, type: :int64, json_name: "lastSignedHeight")

  field(:last_chain_heights, 11,
    repeated: true,
    type: Thorchain.Thorchain.LastChainHeight,
    json_name: "lastChainHeights",
    deprecated: false
  )

  field(:reserve_contributors, 12,
    repeated: true,
    type: Thorchain.Types.ReserveContributor,
    json_name: "reserveContributors",
    deprecated: false
  )

  field(:network, 13, type: Thorchain.Types.Network, deprecated: false)

  field(:adv_swap_queue_items, 19,
    repeated: true,
    type: Thorchain.Types.MsgSwap,
    json_name: "advSwapQueueItems",
    deprecated: false
  )

  field(:network_fees, 20,
    repeated: true,
    type: Thorchain.Types.NetworkFee,
    json_name: "networkFees",
    deprecated: false
  )

  field(:chain_contracts, 22,
    repeated: true,
    type: Thorchain.Types.ChainContract,
    json_name: "chainContracts",
    deprecated: false
  )

  field(:THORNames, 23, repeated: true, type: Thorchain.Types.THORName, deprecated: false)
  field(:mimirs, 24, repeated: true, type: Thorchain.Thorchain.Mimir, deprecated: false)
  field(:store_version, 25, type: :int64, json_name: "storeVersion", deprecated: true)

  field(:bond_providers, 26,
    repeated: true,
    type: Thorchain.Types.BondProviders,
    json_name: "bondProviders",
    deprecated: false
  )

  field(:POL, 27, type: Thorchain.Types.ProtocolOwnedLiquidity, deprecated: false)

  field(:streaming_swaps, 29,
    repeated: true,
    type: Thorchain.Types.StreamingSwap,
    json_name: "streamingSwaps",
    deprecated: false
  )

  field(:swap_queue_items, 30,
    repeated: true,
    type: Thorchain.Types.MsgSwap,
    json_name: "swapQueueItems",
    deprecated: false
  )

  field(:swapper_clout, 31,
    repeated: true,
    type: Thorchain.Types.SwapperClout,
    json_name: "swapperClout",
    deprecated: false
  )

  field(:trade_accounts, 32,
    repeated: true,
    type: Thorchain.Types.TradeAccount,
    json_name: "tradeAccounts",
    deprecated: false
  )

  field(:trade_units, 33,
    repeated: true,
    type: Thorchain.Types.TradeUnit,
    json_name: "tradeUnits",
    deprecated: false
  )

  field(:outbound_fee_withheld_rune, 34,
    repeated: true,
    type: Thorchain.Common.Coin,
    json_name: "outboundFeeWithheldRune",
    deprecated: false
  )

  field(:outbound_fee_spent_rune, 35,
    repeated: true,
    type: Thorchain.Common.Coin,
    json_name: "outboundFeeSpentRune",
    deprecated: false
  )

  field(:rune_providers, 36,
    repeated: true,
    type: Thorchain.Types.RUNEProvider,
    json_name: "runeProviders",
    deprecated: false
  )

  field(:rune_pool, 37, type: Thorchain.Types.RUNEPool, json_name: "runePool", deprecated: false)
  field(:nodeMimirs, 38, repeated: true, type: Thorchain.Types.NodeMimir, deprecated: false)

  field(:affiliate_collectors, 39,
    repeated: true,
    type: Thorchain.Types.AffiliateFeeCollector,
    json_name: "affiliateCollectors",
    deprecated: false
  )

  field(:secured_assets, 41,
    repeated: true,
    type: Thorchain.Types.SecuredAsset,
    json_name: "securedAssets",
    deprecated: false
  )

  field(:tcy_claimers, 42,
    repeated: true,
    type: Thorchain.Types.TCYClaimer,
    json_name: "tcyClaimers",
    deprecated: false
  )

  field(:tcy_stakers, 43,
    repeated: true,
    type: Thorchain.Types.TCYStaker,
    json_name: "tcyStakers",
    deprecated: false
  )

  field(:reference_memos, 44,
    repeated: true,
    type: Thorchain.Types.ReferenceMemo,
    json_name: "referenceMemos",
    deprecated: false
  )

  field(:pol_reserve_deposits, 45,
    repeated: true,
    type: Thorchain.Types.POLReserveDeposit,
    json_name: "polReserveDeposits",
    deprecated: false
  )

  field(:dynamic_fee_records, 46,
    repeated: true,
    type: Thorchain.Types.DynamicFeeRecord,
    json_name: "dynamicFeeRecords",
    deprecated: false
  )

  field(:dynamic_fee_accumulators, 47,
    repeated: true,
    type: Thorchain.Types.DynamicFeeAccumulator,
    json_name: "dynamicFeeAccumulators",
    deprecated: false
  )

  field(:last_observed_dynamic_fee_epoch_blocks, 48,
    type: :int64,
    json_name: "lastObservedDynamicFeeEpochBlocks"
  )
end
