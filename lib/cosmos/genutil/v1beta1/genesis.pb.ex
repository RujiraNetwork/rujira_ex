defmodule Cosmos.Genutil.V1beta1.GenesisState do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:gen_txs, 1, repeated: true, type: :bytes, json_name: "genTxs", deprecated: false)
end
