defmodule Thorchain.Types.QueryLiquidityProviderRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asset, 1, type: :string)
  field(:address, 2, type: :string)
  field(:height, 3, type: :string)
end

defmodule Thorchain.Types.QueryLiquidityProviderResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asset, 1, type: :string, deprecated: false)
  field(:rune_address, 2, type: :string, json_name: "runeAddress")
  field(:asset_address, 3, type: :string, json_name: "assetAddress")
  field(:last_add_height, 4, type: :int64, json_name: "lastAddHeight")
  field(:last_withdraw_height, 5, type: :int64, json_name: "lastWithdrawHeight")
  field(:units, 6, type: :string, deprecated: false)
  field(:pending_rune, 7, type: :string, json_name: "pendingRune", deprecated: false)
  field(:pending_asset, 8, type: :string, json_name: "pendingAsset", deprecated: false)
  field(:pending_tx_id, 9, type: :string, json_name: "pendingTxId")
  field(:rune_deposit_value, 10, type: :string, json_name: "runeDepositValue", deprecated: false)

  field(:asset_deposit_value, 11,
    type: :string,
    json_name: "assetDepositValue",
    deprecated: false
  )

  field(:rune_redeem_value, 12, type: :string, json_name: "runeRedeemValue")
  field(:asset_redeem_value, 13, type: :string, json_name: "assetRedeemValue")
  field(:luvi_deposit_value, 14, type: :string, json_name: "luviDepositValue")
  field(:luvi_redeem_value, 15, type: :string, json_name: "luviRedeemValue")
  field(:luvi_growth_pct, 16, type: :string, json_name: "luviGrowthPct")
end

defmodule Thorchain.Types.QueryLiquidityProvidersRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asset, 1, type: :string)
  field(:height, 2, type: :string)
end

defmodule Thorchain.Types.QueryLiquidityProvidersResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:liquidity_providers, 1,
    repeated: true,
    type: Thorchain.Types.QueryLiquidityProviderResponse,
    json_name: "liquidityProviders"
  )
end
