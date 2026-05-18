defmodule Thorchain.Types.QueryScheduledOutboundRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
end

defmodule Thorchain.Types.QueryPendingOutboundRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
end

defmodule Thorchain.Types.QueryOutboundResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx_out_items, 1,
    repeated: true,
    type: Thorchain.Types.QueryTxOutItem,
    json_name: "txOutItems"
  )
end

defmodule Thorchain.Types.QueryTxOutItem do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 10, type: :int64)
  field(:vault_pub_key, 3, type: :string, json_name: "vaultPubKey")
  field(:in_hash, 8, type: :string, json_name: "inHash")
  field(:out_hash, 9, type: :string, json_name: "outHash")
  field(:chain, 1, type: :string, deprecated: false)
  field(:to_address, 2, type: :string, json_name: "toAddress", deprecated: false)
  field(:coin, 4, type: Thorchain.Common.Coin, deprecated: false)

  field(:max_gas, 6,
    repeated: true,
    type: Thorchain.Common.Coin,
    json_name: "maxGas",
    deprecated: false
  )

  field(:gas_rate, 7, type: :int64, json_name: "gasRate")
  field(:memo, 5, type: :string)
  field(:original_memo, 16, type: :string, json_name: "originalMemo")
  field(:aggregator, 12, type: :string)
  field(:aggregator_target_asset, 13, type: :string, json_name: "aggregatorTargetAsset")
  field(:aggregator_target_limit, 14, type: :string, json_name: "aggregatorTargetLimit")
  field(:clout_spent, 11, type: :string, json_name: "cloutSpent")
  field(:vault_pub_key_eddsa, 15, type: :string, json_name: "vaultPubKeyEddsa")
end
