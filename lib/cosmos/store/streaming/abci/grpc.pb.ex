defmodule Cosmos.Store.Streaming.Abci.ListenFinalizeBlockRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:req, 1, type: Tendermint.Abci.RequestFinalizeBlock)
  field(:res, 2, type: Tendermint.Abci.ResponseFinalizeBlock)
end

defmodule Cosmos.Store.Streaming.Abci.ListenFinalizeBlockResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Store.Streaming.Abci.ListenCommitRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:block_height, 1, type: :int64, json_name: "blockHeight")
  field(:res, 2, type: Tendermint.Abci.ResponseCommit)

  field(:change_set, 3,
    repeated: true,
    type: Cosmos.Store.V1beta1.StoreKVPair,
    json_name: "changeSet"
  )
end

defmodule Cosmos.Store.Streaming.Abci.ListenCommitResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Store.Streaming.Abci.ABCIListenerService.Service do
  @moduledoc false

  use GRPC.Service,
    name: "cosmos.store.streaming.abci.ABCIListenerService",
    protoc_gen_elixir_version: "0.13.0"

  rpc(
    :ListenFinalizeBlock,
    Cosmos.Store.Streaming.Abci.ListenFinalizeBlockRequest,
    Cosmos.Store.Streaming.Abci.ListenFinalizeBlockResponse
  )

  rpc(
    :ListenCommit,
    Cosmos.Store.Streaming.Abci.ListenCommitRequest,
    Cosmos.Store.Streaming.Abci.ListenCommitResponse
  )
end

defmodule Cosmos.Store.Streaming.Abci.ABCIListenerService.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.Store.Streaming.Abci.ABCIListenerService.Service
end
