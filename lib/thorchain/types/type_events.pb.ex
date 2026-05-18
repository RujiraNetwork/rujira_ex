defmodule Thorchain.Types.PendingLiquidityType do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:add, 0)
  field(:withdraw, 1)
end

defmodule Thorchain.Types.BondType do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:bond_paid, 0)
  field(:bond_returned, 1)
  field(:bond_reward, 2)
  field(:bond_cost, 3)
end

defmodule Thorchain.Types.MintBurnSupplyType do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:mint, 0)
  field(:burn, 1)
end

defmodule Thorchain.Types.PoolMod do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asset, 1, type: Thorchain.Common.Asset, deprecated: false)
  field(:rune_amt, 2, type: :string, json_name: "runeAmt", deprecated: false)
  field(:rune_add, 3, type: :bool, json_name: "runeAdd")
  field(:asset_amt, 4, type: :string, json_name: "assetAmt", deprecated: false)
  field(:asset_add, 5, type: :bool, json_name: "assetAdd")
end

defmodule Thorchain.Types.EventLimitSwap do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:source, 1, type: Thorchain.Common.Coin, deprecated: false)
  field(:target, 2, type: Thorchain.Common.Coin, deprecated: false)
  field(:tx_id, 3, type: :string, json_name: "txId", deprecated: false)
end

defmodule Thorchain.Types.EventModifyLimitSwap do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:from, 1, type: :string, deprecated: false)
  field(:source, 2, type: Thorchain.Common.Coin, deprecated: false)
  field(:target, 3, type: Thorchain.Common.Coin, deprecated: false)

  field(:modified_target_amount, 4,
    type: :string,
    json_name: "modifiedTargetAmount",
    deprecated: false
  )
end

defmodule Thorchain.Types.EventLimitSwapClose do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx_id, 1, type: :string, json_name: "txId", deprecated: false)
  field(:reason, 2, type: :string)
  field(:block_height, 3, type: :int64, json_name: "blockHeight")
end

defmodule Thorchain.Types.EventStreamingSwap do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx_id, 1, type: :string, json_name: "txId", deprecated: false)
  field(:interval, 2, type: :uint64)
  field(:quantity, 3, type: :uint64)
  field(:count, 4, type: :uint64)
  field(:last_height, 5, type: :int64, json_name: "lastHeight")
  field(:trade_target, 6, type: :string, json_name: "tradeTarget", deprecated: false)
  field(:deposit, 7, type: Thorchain.Common.Coin, deprecated: false)
  field(:in, 8, type: Thorchain.Common.Coin, deprecated: false)
  field(:out, 9, type: Thorchain.Common.Coin, deprecated: false)
  field(:failed_swaps, 10, repeated: true, type: :uint64, json_name: "failedSwaps")
  field(:failed_swap_reasons, 11, repeated: true, type: :string, json_name: "failedSwapReasons")
end

defmodule Thorchain.Types.EventSwap do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pool, 1, type: Thorchain.Common.Asset, deprecated: false)
  field(:swap_target, 2, type: :string, json_name: "swapTarget", deprecated: false)
  field(:swap_slip, 3, type: :string, json_name: "swapSlip", deprecated: false)
  field(:liquidity_fee, 4, type: :string, json_name: "liquidityFee", deprecated: false)

  field(:liquidity_fee_in_rune, 5,
    type: :string,
    json_name: "liquidityFeeInRune",
    deprecated: false
  )

  field(:in_tx, 6, type: Thorchain.Common.Tx, json_name: "inTx", deprecated: false)
  field(:out_txs, 7, type: Thorchain.Common.Tx, json_name: "outTxs", deprecated: false)
  field(:emit_asset, 8, type: Thorchain.Common.Coin, json_name: "emitAsset", deprecated: false)
  field(:synth_units, 9, type: :string, json_name: "synthUnits", deprecated: false)
  field(:streaming_swap_quantity, 10, type: :uint64, json_name: "streamingSwapQuantity")
  field(:streaming_swap_count, 11, type: :uint64, json_name: "streamingSwapCount")
  field(:pool_slip, 12, type: :string, json_name: "poolSlip", deprecated: false)
end

defmodule Thorchain.Types.EventAffiliateFee do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx_id, 1, type: :string, json_name: "txId", deprecated: false)
  field(:memo, 2, type: :string)
  field(:thorname, 3, type: :string)
  field(:rune_address, 4, type: :string, json_name: "runeAddress", deprecated: false)
  field(:asset, 5, type: Thorchain.Common.Asset, deprecated: false)
  field(:gross_amount, 6, type: :string, json_name: "grossAmount", deprecated: false)
  field(:fee_bps, 7, type: :uint64, json_name: "feeBps")
  field(:fee_amount, 8, type: :string, json_name: "feeAmount", deprecated: false)
end

defmodule Thorchain.Types.EventAddLiquidity do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pool, 1, type: Thorchain.Common.Asset, deprecated: false)
  field(:provider_units, 2, type: :string, json_name: "providerUnits", deprecated: false)
  field(:rune_address, 3, type: :string, json_name: "runeAddress", deprecated: false)
  field(:rune_amount, 4, type: :string, json_name: "runeAmount", deprecated: false)
  field(:asset_amount, 5, type: :string, json_name: "assetAmount", deprecated: false)
  field(:rune_tx_id, 6, type: :string, json_name: "runeTxId", deprecated: false)
  field(:asset_tx_id, 7, type: :string, json_name: "assetTxId", deprecated: false)
  field(:asset_address, 8, type: :string, json_name: "assetAddress", deprecated: false)
end

defmodule Thorchain.Types.EventWithdraw do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pool, 1, type: Thorchain.Common.Asset, deprecated: false)
  field(:provider_units, 2, type: :string, json_name: "providerUnits", deprecated: false)
  field(:basis_points, 3, type: :int64, json_name: "basisPoints")
  field(:asymmetry, 4, type: :bytes, deprecated: false)
  field(:in_tx, 5, type: Thorchain.Common.Tx, json_name: "inTx", deprecated: false)
  field(:emit_asset, 6, type: :string, json_name: "emitAsset", deprecated: false)
  field(:emit_rune, 7, type: :string, json_name: "emitRune", deprecated: false)
end

defmodule Thorchain.Types.EventPendingLiquidity do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pool, 1, type: Thorchain.Common.Asset, deprecated: false)

  field(:pending_type, 2,
    type: Thorchain.Types.PendingLiquidityType,
    json_name: "pendingType",
    enum: true
  )

  field(:rune_address, 3, type: :string, json_name: "runeAddress", deprecated: false)
  field(:rune_amount, 4, type: :string, json_name: "runeAmount", deprecated: false)
  field(:asset_address, 5, type: :string, json_name: "assetAddress", deprecated: false)
  field(:asset_amount, 6, type: :string, json_name: "assetAmount", deprecated: false)
  field(:rune_tx_id, 7, type: :string, json_name: "runeTxId", deprecated: false)
  field(:asset_tx_id, 8, type: :string, json_name: "assetTxId", deprecated: false)
end

defmodule Thorchain.Types.EventDonate do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pool, 1, type: Thorchain.Common.Asset, deprecated: false)
  field(:in_tx, 2, type: Thorchain.Common.Tx, json_name: "inTx", deprecated: false)
end

defmodule Thorchain.Types.EventPool do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pool, 1, type: Thorchain.Common.Asset, deprecated: false)
  field(:Status, 2, type: Thorchain.Types.PoolStatus, enum: true)
end

defmodule Thorchain.Types.PoolAmt do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asset, 1, type: Thorchain.Common.Asset, deprecated: false)
  field(:amount, 2, type: :int64)
end

defmodule Thorchain.Types.EventRewards do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:bond_reward, 1, type: :string, json_name: "bondReward", deprecated: false)

  field(:pool_rewards, 2,
    repeated: true,
    type: Thorchain.Types.PoolAmt,
    json_name: "poolRewards",
    deprecated: false
  )

  field(:dev_fund_reward, 3, type: :string, json_name: "devFundReward", deprecated: false)
  field(:income_burn, 4, type: :string, json_name: "incomeBurn", deprecated: false)
  field(:tcy_stake_reward, 5, type: :string, json_name: "tcyStakeReward", deprecated: false)

  field(:marketing_fund_reward, 6,
    type: :string,
    json_name: "marketingFundReward",
    deprecated: false
  )

  field(:pol_reserve_reward, 7, type: :string, json_name: "polReserveReward", deprecated: false)
end

defmodule Thorchain.Types.EventRefund do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:code, 1, type: :uint32)
  field(:reason, 2, type: :string)
  field(:in_tx, 3, type: Thorchain.Common.Tx, json_name: "inTx", deprecated: false)
  field(:fee, 4, type: Thorchain.Common.Fee, deprecated: false)
end

defmodule Thorchain.Types.EventBond do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:amount, 1, type: :string, deprecated: false)
  field(:bond_type, 2, type: Thorchain.Types.BondType, json_name: "bondType", enum: true)
  field(:tx_in, 3, type: Thorchain.Common.Tx, json_name: "txIn", deprecated: false)
  field(:node_address, 4, type: :bytes, json_name: "nodeAddress", deprecated: false)
  field(:bond_address, 5, type: :bytes, json_name: "bondAddress", deprecated: false)
end

defmodule Thorchain.Types.EventReBond do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:amount, 1, type: :string, deprecated: false)
  field(:tx_in, 2, type: Thorchain.Common.Tx, json_name: "txIn", deprecated: false)
  field(:node_address, 3, type: :bytes, json_name: "nodeAddress", deprecated: false)
  field(:old_bond_address, 4, type: :bytes, json_name: "oldBondAddress", deprecated: false)
  field(:new_bond_address, 5, type: :bytes, json_name: "newBondAddress", deprecated: false)
end

defmodule Thorchain.Types.GasPool do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asset, 1, type: Thorchain.Common.Asset, deprecated: false)
  field(:rune_amt, 2, type: :string, json_name: "runeAmt", deprecated: false)
  field(:asset_amt, 3, type: :string, json_name: "assetAmt", deprecated: false)
  field(:count, 4, type: :int64)
end

defmodule Thorchain.Types.EventGas do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pools, 1, repeated: true, type: Thorchain.Types.GasPool, deprecated: false)
end

defmodule Thorchain.Types.EventReserve do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:reserve_contributor, 1,
    type: Thorchain.Types.ReserveContributor,
    json_name: "reserveContributor",
    deprecated: false
  )

  field(:in_tx, 2, type: Thorchain.Common.Tx, json_name: "inTx", deprecated: false)
end

defmodule Thorchain.Types.EventScheduledOutbound do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:out_tx, 1, type: Thorchain.Types.TxOutItem, json_name: "outTx", deprecated: false)
end

defmodule Thorchain.Types.EventSecurity do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:msg, 1, type: :string)
  field(:tx, 2, type: Thorchain.Common.Tx, deprecated: false)
end

defmodule Thorchain.Types.EventSlash do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pool, 1, type: Thorchain.Common.Asset, deprecated: false)

  field(:slash_amount, 2,
    repeated: true,
    type: Thorchain.Types.PoolAmt,
    json_name: "slashAmount",
    deprecated: false
  )
end

defmodule Thorchain.Types.EventErrata do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx_id, 1, type: :string, json_name: "txId", deprecated: false)
  field(:pools, 2, repeated: true, type: Thorchain.Types.PoolMod, deprecated: false)
end

defmodule Thorchain.Types.EventFee do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx_id, 1, type: :string, json_name: "txId", deprecated: false)
  field(:fee, 2, type: Thorchain.Common.Fee, deprecated: false)
  field(:synth_units, 3, type: :string, json_name: "synthUnits", deprecated: false)
end

defmodule Thorchain.Types.EventOutbound do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:in_tx_id, 1, type: :string, json_name: "inTxId", deprecated: false)
  field(:tx, 2, type: Thorchain.Common.Tx, deprecated: false)
end

defmodule Thorchain.Types.EventTssKeygenSuccess do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pub_key, 1, type: :string, json_name: "pubKey", deprecated: false)
  field(:members, 2, repeated: true, type: :string)
  field(:height, 3, type: :int64)
end

defmodule Thorchain.Types.EventTssKeygenFailure do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:fail_reason, 1, type: :string, json_name: "failReason")
  field(:is_unicast, 2, type: :bool, json_name: "isUnicast")
  field(:blame_nodes, 3, repeated: true, type: :string, json_name: "blameNodes")
  field(:round, 4, type: :string)
  field(:height, 5, type: :int64)
end

defmodule Thorchain.Types.EventTssKeygenMetric do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pub_key, 1, type: :string, json_name: "pubKey", deprecated: false)
  field(:median_duration_ms, 2, type: :int64, json_name: "medianDurationMs")
end

defmodule Thorchain.Types.EventTssKeysignMetric do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx_id, 1, type: :string, json_name: "txId", deprecated: false)
  field(:median_duration_ms, 2, type: :int64, json_name: "medianDurationMs")
end

defmodule Thorchain.Types.EventSlashPoint do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:node_address, 1, type: :bytes, json_name: "nodeAddress", deprecated: false)
  field(:slash_points, 2, type: :int64, json_name: "slashPoints")
  field(:reason, 3, type: :string)
end

defmodule Thorchain.Types.EventPoolBalanceChanged do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pool_change, 1,
    type: Thorchain.Types.PoolMod,
    json_name: "poolChange",
    deprecated: false
  )

  field(:reason, 2, type: :string)
end

defmodule Thorchain.Types.EventMintBurn do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:supply, 1, type: Thorchain.Types.MintBurnSupplyType, enum: true)
  field(:denom, 2, type: :string)
  field(:amount, 3, type: :string, deprecated: false)
  field(:reason, 4, type: :string)
end

defmodule Thorchain.Types.EventTradeAccountDeposit do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:amount, 1, type: :string, deprecated: false)
  field(:asset, 2, type: Thorchain.Common.Asset, deprecated: false)
  field(:asset_address, 3, type: :string, json_name: "assetAddress", deprecated: false)
  field(:rune_address, 4, type: :string, json_name: "runeAddress", deprecated: false)
  field(:tx_id, 5, type: :string, json_name: "txId", deprecated: false)
end

defmodule Thorchain.Types.EventTradeAccountWithdraw do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:amount, 1, type: :string, deprecated: false)
  field(:asset, 2, type: Thorchain.Common.Asset, deprecated: false)
  field(:asset_address, 3, type: :string, json_name: "assetAddress", deprecated: false)
  field(:rune_address, 4, type: :string, json_name: "runeAddress", deprecated: false)
  field(:tx_id, 5, type: :string, json_name: "txId", deprecated: false)
end

defmodule Thorchain.Types.EventSecuredAssetDeposit do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:amount, 1, type: :string, deprecated: false)
  field(:asset, 2, type: Thorchain.Common.Asset, deprecated: false)
  field(:asset_address, 3, type: :string, json_name: "assetAddress", deprecated: false)
  field(:rune_address, 4, type: :string, json_name: "runeAddress", deprecated: false)
  field(:tx_id, 5, type: :string, json_name: "txId", deprecated: false)
end

defmodule Thorchain.Types.EventSecuredAssetWithdraw do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:amount, 1, type: :string, deprecated: false)
  field(:asset, 2, type: Thorchain.Common.Asset, deprecated: false)
  field(:asset_address, 3, type: :string, json_name: "assetAddress", deprecated: false)
  field(:rune_address, 4, type: :string, json_name: "runeAddress", deprecated: false)
  field(:tx_id, 5, type: :string, json_name: "txId", deprecated: false)
end

defmodule Thorchain.Types.EventRUNEPoolDeposit do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:rune_address, 1, type: :bytes, json_name: "runeAddress", deprecated: false)
  field(:rune_amount, 2, type: :string, json_name: "runeAmount", deprecated: false)
  field(:units, 3, type: :string, deprecated: false)
  field(:tx_id, 4, type: :string, json_name: "txId", deprecated: false)
end

defmodule Thorchain.Types.EventRUNEPoolWithdraw do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:rune_address, 1, type: :bytes, json_name: "runeAddress", deprecated: false)
  field(:basis_points, 2, type: :int64, json_name: "basisPoints")
  field(:rune_amount, 3, type: :string, json_name: "runeAmount", deprecated: false)
  field(:units, 4, type: :string, deprecated: false)
  field(:tx_id, 5, type: :string, json_name: "txId", deprecated: false)
  field(:affiliate_basis_pts, 6, type: :int64, json_name: "affiliateBasisPts")
  field(:affiliate_amount, 7, type: :string, json_name: "affiliateAmount", deprecated: false)
  field(:affiliate_address, 8, type: :string, json_name: "affiliateAddress", deprecated: false)
end

defmodule Thorchain.Types.EventTHORName do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:name, 1, type: :string)
  field(:chain, 2, type: :string, deprecated: false)
  field(:address, 3, type: :string, deprecated: false)
  field(:registration_fee, 4, type: :string, json_name: "registrationFee", deprecated: false)
  field(:fund_amt, 5, type: :string, json_name: "fundAmt", deprecated: false)
  field(:expire, 6, type: :int64)
  field(:owner, 7, type: :bytes, deprecated: false)
end

defmodule Thorchain.Types.EventSetMimir do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:key, 1, type: :string)
  field(:value, 2, type: :string)
end

defmodule Thorchain.Types.EventSetNodeMimir do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:key, 1, type: :string)
  field(:value, 2, type: :string)
  field(:address, 3, type: :string)
end

defmodule Thorchain.Types.EventVersion do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:version, 1, type: :string)
end

defmodule Thorchain.Types.EventSwitch do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:amount, 1, type: :string, deprecated: false)
  field(:asset, 2, type: Thorchain.Common.Asset, deprecated: false)
  field(:asset_address, 3, type: :string, json_name: "assetAddress", deprecated: false)
  field(:rune_address, 4, type: :string, json_name: "runeAddress", deprecated: false)
  field(:tx_id, 5, type: :string, json_name: "txId", deprecated: false)
end

defmodule Thorchain.Types.EventOperatorRotate do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:signer, 1, type: :bytes, deprecated: false)
  field(:node_address, 2, type: :bytes, json_name: "nodeAddress", deprecated: false)
  field(:operator_address, 3, type: :bytes, json_name: "operatorAddress", deprecated: false)
end

defmodule Thorchain.Types.EventTCYDistribution do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:rune_address, 1, type: :bytes, json_name: "runeAddress", deprecated: false)
  field(:rune_amount, 2, type: :string, json_name: "runeAmount", deprecated: false)
end

defmodule Thorchain.Types.EventTCYClaim do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:rune_address, 1, type: :string, json_name: "runeAddress", deprecated: false)
  field(:tcy_amount, 2, type: :string, json_name: "tcyAmount", deprecated: false)
  field(:l1_address, 3, type: :string, json_name: "l1Address", deprecated: false)
  field(:asset, 4, type: Thorchain.Common.Asset, deprecated: false)
end

defmodule Thorchain.Types.EventTCYStake do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)
  field(:amount, 2, type: :string, deprecated: false)
end

defmodule Thorchain.Types.EventTCYUnstake do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)
  field(:amount, 2, type: :string, deprecated: false)
end

defmodule Thorchain.Types.EventOraclePrice do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:symbol, 1, type: :string)
  field(:price, 2, type: :string)
end

defmodule Thorchain.Types.EventFailedOutboundRecovery do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:in_tx_id, 1, type: :string, json_name: "inTxId", deprecated: false)
  field(:coin, 2, type: Thorchain.Common.Coin, deprecated: false)
  field(:recovery_type, 3, type: :string, json_name: "recoveryType")
  field(:destination, 4, type: :string, deprecated: false)
  field(:memo, 5, type: :string)
end

defmodule Thorchain.Types.AssetOverSolvency do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asset, 1, type: Thorchain.Common.Asset, deprecated: false)
  field(:over_solvent_amount, 2, type: :string, json_name: "overSolventAmount", deprecated: false)

  field(:swap_to_reserve_amount, 3,
    type: :string,
    json_name: "swapToReserveAmount",
    deprecated: false
  )
end

defmodule Thorchain.Types.EventVaultOverSolvency do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:assets, 1, repeated: true, type: Thorchain.Types.AssetOverSolvency, deprecated: false)
  field(:over_solvency_basis_points, 2, type: :int64, json_name: "overSolvencyBasisPoints")
end

defmodule Thorchain.Types.EventPOLReserveDeploy do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pool, 1, type: Thorchain.Common.Asset, deprecated: false)
  field(:rune_amount, 2, type: :string, json_name: "runeAmount", deprecated: false)
end
