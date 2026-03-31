defmodule Thorchain.Types.ObservedNetworkFeeVoter do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:block_height, 1, type: :int64, json_name: "blockHeight")
  field(:report_block_height, 2, type: :int64, json_name: "reportBlockHeight")
  field(:chain, 3, type: :string, deprecated: false)
  field(:signers, 4, repeated: true, type: :string)
  field(:fee_rate, 5, type: :int64, json_name: "feeRate")
  field(:transaction_size, 6, type: :int64, json_name: "transactionSize")
end
