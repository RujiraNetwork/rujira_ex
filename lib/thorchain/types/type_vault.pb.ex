defmodule Thorchain.Types.VaultType do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:UnknownVault, 0)
  field(:AsgardVault, 1)
end

defmodule Thorchain.Types.VaultStatus do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:InactiveVault, 0)
  field(:ActiveVault, 1)
  field(:RetiringVault, 2)
  field(:InitVault, 3)
end

defmodule Thorchain.Types.Vault do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:block_height, 1, type: :int64, json_name: "blockHeight")
  field(:pub_key, 2, type: :string, json_name: "pubKey", deprecated: false)
  field(:coins, 3, repeated: true, type: Thorchain.Common.Coin, deprecated: false)
  field(:type, 4, type: Thorchain.Types.VaultType, enum: true)
  field(:status, 5, type: Thorchain.Types.VaultStatus, enum: true)
  field(:status_since, 6, type: :int64, json_name: "statusSince")
  field(:membership, 7, repeated: true, type: :string)
  field(:chains, 8, repeated: true, type: :string)
  field(:inbound_tx_count, 9, type: :int64, json_name: "inboundTxCount")
  field(:outbound_tx_count, 10, type: :int64, json_name: "outboundTxCount")

  field(:pending_tx_block_heights, 11,
    repeated: true,
    type: :int64,
    json_name: "pendingTxBlockHeights"
  )

  field(:routers, 22, repeated: true, type: Thorchain.Types.ChainContract, deprecated: false)
  field(:frozen, 23, repeated: true, type: :string)
end
