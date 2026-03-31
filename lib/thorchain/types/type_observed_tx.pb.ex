defmodule Thorchain.Types.Status do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:incomplete, 0)
  field(:done, 1)
  field(:reverted, 2)
end

defmodule Thorchain.Types.ObservedTx do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx, 1, type: Thorchain.Common.Tx, deprecated: false)
  field(:status, 2, type: Thorchain.Types.Status, enum: true)
  field(:out_hashes, 3, repeated: true, type: :string, json_name: "outHashes")
  field(:block_height, 4, type: :int64, json_name: "blockHeight")
  field(:signers, 5, repeated: true, type: :string)
  field(:observed_pub_key, 6, type: :string, json_name: "observedPubKey", deprecated: false)
  field(:keysign_ms, 7, type: :int64, json_name: "keysignMs")
  field(:finalise_height, 8, type: :int64, json_name: "finaliseHeight")
  field(:aggregator, 9, type: :string)
  field(:aggregator_target, 10, type: :string, json_name: "aggregatorTarget")

  field(:aggregator_target_limit, 11,
    type: :string,
    json_name: "aggregatorTargetLimit",
    deprecated: false
  )
end

defmodule Thorchain.Types.ObservedTxVoter do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx_id, 1, type: :string, json_name: "txId", deprecated: false)
  field(:tx, 2, type: Thorchain.Types.ObservedTx, deprecated: false)
  field(:height, 3, type: :int64)
  field(:txs, 4, repeated: true, type: Thorchain.Types.ObservedTx, deprecated: false)
  field(:actions, 5, repeated: true, type: Thorchain.Types.TxOutItem, deprecated: false)

  field(:out_txs, 6,
    repeated: true,
    type: Thorchain.Common.Tx,
    json_name: "outTxs",
    deprecated: false
  )

  field(:finalised_height, 7, type: :int64, json_name: "finalisedHeight")
  field(:updated_vault, 8, type: :bool, json_name: "updatedVault")
  field(:reverted, 9, type: :bool)
  field(:outbound_height, 10, type: :int64, json_name: "outboundHeight")
end
