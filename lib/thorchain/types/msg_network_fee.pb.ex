defmodule Thorchain.Types.MsgNetworkFee do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:block_height, 1, type: :int64, json_name: "blockHeight")
  field(:chain, 2, type: :string, deprecated: false)
  field(:transaction_size, 3, type: :uint64, json_name: "transactionSize")
  field(:transaction_fee_rate, 4, type: :uint64, json_name: "transactionFeeRate")
  field(:signer, 5, type: :bytes, deprecated: false)
end
