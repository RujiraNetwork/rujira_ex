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

  field(:chain, 1, type: :string, deprecated: false)
  field(:to_address, 2, type: :string, json_name: "toAddress", deprecated: false)
  field(:vault_pub_key, 3, type: :string, json_name: "vaultPubKey")
  field(:coin, 4, type: Thorchain.Common.Coin, deprecated: false)
  field(:memo, 5, type: :string)

  field(:max_gas, 6,
    repeated: true,
    type: Thorchain.Common.Coin,
    json_name: "maxGas",
    deprecated: false
  )

  field(:gas_rate, 7, type: :int64, json_name: "gasRate")
  field(:in_hash, 8, type: :string, json_name: "inHash")
  field(:out_hash, 9, type: :string, json_name: "outHash")
  field(:height, 10, type: :int64)
  field(:clout_spent, 11, type: :string, json_name: "cloutSpent")
end
