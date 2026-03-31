defmodule Thorchain.Types.NetworkFee do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:chain, 1, type: :string, deprecated: false)
  field(:transaction_size, 2, type: :uint64, json_name: "transactionSize")
  field(:transaction_fee_rate, 3, type: :uint64, json_name: "transactionFeeRate")
end
