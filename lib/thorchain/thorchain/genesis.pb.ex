alias Thorchain.Types

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

  field(:pools, 1, repeated: true, type: Types.Pool, deprecated: false)

  field(:liquidity_providers, 2,
    repeated: true,
    type: Types.LiquidityProvider,
    json_name: "liquidityProviders",
    deprecated: false
  )

  field(:observed_tx_in_voters, 3,
    repeated: true,
    type: Types.ObservedTxVoter,
    json_name: "observedTxInVoters",
    deprecated: false
  )

  field(:observed_tx_out_voters, 4,
    repeated: true,
    type: Types.ObservedTxVoter,
    json_name: "observedTxOutVoters",
    deprecated: false
  )

  field(:tx_outs, 5, repeated: true, type: Types.TxOut, json_name: "txOuts", deprecated: false)

  field(:node_accounts, 6,
    repeated: true,
    type: Types.NodeAccount,
    json_name: "nodeAccounts",
    deprecated: false
  )

  field(:vaults, 7, repeated: true, type: Types.Vault, deprecated: false)
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
    type: Types.ReserveContributor,
    json_name: "reserveContributors",
    deprecated: false
  )

  field(:network, 13, type: Types.Network, deprecated: false)

  field(:orderbook_items, 19,
    repeated: true,
    type: Types.MsgSwap,
    json_name: "orderbookItems",
    deprecated: false
  )

  field(:network_fees, 20,
    repeated: true,
    type: Types.NetworkFee,
    json_name: "networkFees",
    deprecated: false
  )

  field(:chain_contracts, 22,
    repeated: true,
    type: Types.ChainContract,
    json_name: "chainContracts",
    deprecated: false
  )

  field(:THORNames, 23, repeated: true, type: Types.THORName, deprecated: false)
  field(:mimirs, 24, repeated: true, type: Thorchain.Thorchain.Mimir, deprecated: false)
  field(:store_version, 25, type: :int64, json_name: "storeVersion")

  field(:bond_providers, 26,
    repeated: true,
    type: Types.BondProviders,
    json_name: "bondProviders",
    deprecated: false
  )

  field(:POL, 27, type: Types.ProtocolOwnedLiquidity, deprecated: false)

  field(:streaming_swaps, 29,
    repeated: true,
    type: Types.StreamingSwap,
    json_name: "streamingSwaps",
    deprecated: false
  )

  field(:swap_queue_items, 30,
    repeated: true,
    type: Types.MsgSwap,
    json_name: "swapQueueItems",
    deprecated: false
  )

  field(:swapper_clout, 31,
    repeated: true,
    type: Types.SwapperClout,
    json_name: "swapperClout",
    deprecated: false
  )

  field(:trade_accounts, 32,
    repeated: true,
    type: Types.TradeAccount,
    json_name: "tradeAccounts",
    deprecated: false
  )

  field(:trade_units, 33,
    repeated: true,
    type: Types.TradeUnit,
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
    type: Types.RUNEProvider,
    json_name: "runeProviders",
    deprecated: false
  )

  field(:rune_pool, 37, type: Types.RUNEPool, json_name: "runePool", deprecated: false)
  field(:nodeMimirs, 38, repeated: true, type: Types.NodeMimir, deprecated: false)

  field(:affiliate_collectors, 39,
    repeated: true,
    type: Types.AffiliateFeeCollector,
    json_name: "affiliateCollectors",
    deprecated: false
  )

  field(:secured_assets, 41,
    repeated: true,
    type: Types.SecuredAsset,
    json_name: "securedAssets",
    deprecated: false
  )
end
