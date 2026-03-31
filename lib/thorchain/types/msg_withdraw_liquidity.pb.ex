defmodule Thorchain.Types.MsgWithdrawLiquidity do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx, 1, type: Thorchain.Common.Tx, deprecated: false)
  field(:withdraw_address, 2, type: :string, json_name: "withdrawAddress", deprecated: false)
  field(:basis_points, 3, type: :string, json_name: "basisPoints", deprecated: false)
  field(:asset, 4, type: Thorchain.Common.Asset, deprecated: false)

  field(:withdrawal_asset, 5,
    type: Thorchain.Common.Asset,
    json_name: "withdrawalAsset",
    deprecated: false
  )

  field(:signer, 6, type: :bytes, deprecated: false)
end
