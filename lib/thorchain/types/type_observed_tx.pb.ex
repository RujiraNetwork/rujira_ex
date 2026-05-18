defmodule Thorchain.Types.ObservedTxVoter do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx_id, 1, type: :string, json_name: "txId", deprecated: false)
  field(:tx, 2, type: Thorchain.Common.ObservedTx, deprecated: false)
  field(:height, 3, type: :int64)
  field(:txs, 4, repeated: true, type: Thorchain.Common.ObservedTx, deprecated: false)
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
  field(:unfinalized_height, 11, type: :int64, json_name: "unfinalizedHeight")
end
