defmodule Thorchain.Types.LiquidityProvider do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asset, 1, type: Thorchain.Common.Asset, deprecated: false)
  field(:rune_address, 2, type: :string, json_name: "runeAddress", deprecated: false)
  field(:asset_address, 3, type: :string, json_name: "assetAddress", deprecated: false)
  field(:last_add_height, 4, type: :int64, json_name: "lastAddHeight")
  field(:last_withdraw_height, 5, type: :int64, json_name: "lastWithdrawHeight")
  field(:units, 6, type: :string, deprecated: false)
  field(:pending_rune, 7, type: :string, json_name: "pendingRune", deprecated: false)
  field(:pending_asset, 8, type: :string, json_name: "pendingAsset", deprecated: false)
  field(:pending_tx_Id, 9, type: :string, json_name: "pendingTxId", deprecated: false)
  field(:rune_deposit_value, 10, type: :string, json_name: "runeDepositValue", deprecated: false)

  field(:asset_deposit_value, 11,
    type: :string,
    json_name: "assetDepositValue",
    deprecated: false
  )
end
