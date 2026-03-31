defmodule Cosmos.Store.V1beta1.StoreKVPair do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:store_key, 1, type: :string, json_name: "storeKey")
  field(:delete, 2, type: :bool)
  field(:key, 3, type: :bytes)
  field(:value, 4, type: :bytes)
end

defmodule Cosmos.Store.V1beta1.BlockMetadata do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:response_commit, 6, type: Tendermint.Abci.ResponseCommit, json_name: "responseCommit")

  field(:request_finalize_block, 7,
    type: Tendermint.Abci.RequestFinalizeBlock,
    json_name: "requestFinalizeBlock"
  )

  field(:response_finalize_block, 8,
    type: Tendermint.Abci.ResponseFinalizeBlock,
    json_name: "responseFinalizeBlock"
  )
end
