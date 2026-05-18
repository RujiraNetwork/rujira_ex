defmodule Thorchain.Types.QueryVaultRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pub_key, 1, type: :string, json_name: "pubKey")
  field(:height, 2, type: :string)
end

defmodule Thorchain.Types.QueryVaultResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:block_height, 1, type: :int64, json_name: "blockHeight")
  field(:pub_key, 2, type: :string, json_name: "pubKey")
  field(:coins, 3, repeated: true, type: Thorchain.Common.Coin, deprecated: false)
  field(:type, 4, type: :string)
  field(:status, 5, type: :string, deprecated: false)
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

  field(:routers, 12, repeated: true, type: Thorchain.Types.VaultRouter, deprecated: false)
  field(:addresses, 13, repeated: true, type: Thorchain.Types.VaultAddress, deprecated: false)
  field(:frozen, 14, repeated: true, type: :string)
  field(:pub_key_eddsa, 15, type: :string, json_name: "pubKeyEddsa", deprecated: false)
end

defmodule Thorchain.Types.QueryAsgardVaultsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
end

defmodule Thorchain.Types.QueryAsgardVaultsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asgard_vaults, 1,
    repeated: true,
    type: Thorchain.Types.QueryVaultResponse,
    json_name: "asgardVaults"
  )
end

defmodule Thorchain.Types.QueryVaultsPubkeysRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
end

defmodule Thorchain.Types.QueryVaultsPubkeysResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asgard, 1, repeated: true, type: Thorchain.Types.VaultInfo, deprecated: false)
  field(:inactive, 2, repeated: true, type: Thorchain.Types.VaultInfo, deprecated: false)
end

defmodule Thorchain.Types.VaultInfo do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pub_key, 1, type: :string, json_name: "pubKey", deprecated: false)
  field(:routers, 2, repeated: true, type: Thorchain.Types.VaultRouter, deprecated: false)
  field(:pub_key_eddsa, 3, type: :string, json_name: "pubKeyEddsa", deprecated: false)
  field(:membership, 4, repeated: true, type: :string)
end

defmodule Thorchain.Types.VaultRouter do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:chain, 1, type: :string)
  field(:router, 2, type: :string)
end

defmodule Thorchain.Types.VaultAddress do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:chain, 1, type: :string, deprecated: false)
  field(:address, 2, type: :string, deprecated: false)
end

defmodule Thorchain.Types.QueryVaultSolvencyRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
end

defmodule Thorchain.Types.VaultSolvencyAsset do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asset, 1, type: Thorchain.Common.Asset, deprecated: false)
  field(:amount, 2, type: :string, deprecated: false)
end

defmodule Thorchain.Types.QueryVaultSolvencyResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:assets, 1, repeated: true, type: Thorchain.Types.VaultSolvencyAsset, deprecated: false)
end
