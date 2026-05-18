defmodule Thorchain.Types.TxOutItem do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:chain, 1, type: :string, deprecated: false)
  field(:to_address, 2, type: :string, json_name: "toAddress", deprecated: false)
  field(:vault_pub_key, 3, type: :string, json_name: "vaultPubKey", deprecated: false)
  field(:coin, 4, type: Thorchain.Common.Coin, deprecated: false)
  field(:memo, 5, type: :string)
  field(:original_memo, 16, type: :string, json_name: "originalMemo")

  field(:max_gas, 6,
    repeated: true,
    type: Thorchain.Common.Coin,
    json_name: "maxGas",
    deprecated: false
  )

  field(:gas_rate, 7, type: :int64, json_name: "gasRate")
  field(:in_hash, 8, type: :string, json_name: "inHash", deprecated: false)
  field(:out_hash, 9, type: :string, json_name: "outHash", deprecated: false)
  field(:module_name, 10, type: :string, json_name: "-", deprecated: false)
  field(:aggregator, 11, type: :string)
  field(:aggregator_target_asset, 12, type: :string, json_name: "aggregatorTargetAsset")

  field(:aggregator_target_limit, 13,
    type: :string,
    json_name: "aggregatorTargetLimit",
    deprecated: false
  )

  field(:clout_spent, 14, type: :string, json_name: "cloutSpent", deprecated: false)
  field(:vault_pub_key_eddsa, 15, type: :string, json_name: "vaultPubKeyEddsa", deprecated: false)
end

defmodule Thorchain.Types.TxOut do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :int64)

  field(:tx_array, 2,
    repeated: true,
    type: Thorchain.Types.TxOutItem,
    json_name: "txArray",
    deprecated: false
  )
end
