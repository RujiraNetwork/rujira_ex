defmodule Cosmos.Base.Tendermint.V1beta1.GetValidatorSetByHeightRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :int64)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Base.Tendermint.V1beta1.GetValidatorSetByHeightResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:block_height, 1, type: :int64, json_name: "blockHeight")
  field(:validators, 2, repeated: true, type: Cosmos.Base.Tendermint.V1beta1.Validator)
  field(:pagination, 3, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Base.Tendermint.V1beta1.GetLatestValidatorSetRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pagination, 1, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Base.Tendermint.V1beta1.GetLatestValidatorSetResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:block_height, 1, type: :int64, json_name: "blockHeight")
  field(:validators, 2, repeated: true, type: Cosmos.Base.Tendermint.V1beta1.Validator)
  field(:pagination, 3, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Base.Tendermint.V1beta1.Validator do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)
  field(:pub_key, 2, type: Google.Protobuf.Any, json_name: "pubKey")
  field(:voting_power, 3, type: :int64, json_name: "votingPower")
  field(:proposer_priority, 4, type: :int64, json_name: "proposerPriority")
end

defmodule Cosmos.Base.Tendermint.V1beta1.GetBlockByHeightRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :int64)
end

defmodule Cosmos.Base.Tendermint.V1beta1.GetBlockByHeightResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:block_id, 1, type: Tendermint.Types.BlockID, json_name: "blockId")
  field(:block, 2, type: Tendermint.Types.Block)
  field(:sdk_block, 3, type: Cosmos.Base.Tendermint.V1beta1.Block, json_name: "sdkBlock")
end

defmodule Cosmos.Base.Tendermint.V1beta1.GetLatestBlockRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Base.Tendermint.V1beta1.GetLatestBlockResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:block_id, 1, type: Tendermint.Types.BlockID, json_name: "blockId")
  field(:block, 2, type: Tendermint.Types.Block)
  field(:sdk_block, 3, type: Cosmos.Base.Tendermint.V1beta1.Block, json_name: "sdkBlock")
end

defmodule Cosmos.Base.Tendermint.V1beta1.GetSyncingRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Base.Tendermint.V1beta1.GetSyncingResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:syncing, 1, type: :bool)
end

defmodule Cosmos.Base.Tendermint.V1beta1.GetNodeInfoRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Base.Tendermint.V1beta1.GetNodeInfoResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:default_node_info, 1, type: Tendermint.P2p.DefaultNodeInfo, json_name: "defaultNodeInfo")

  field(:application_version, 2,
    type: Cosmos.Base.Tendermint.V1beta1.VersionInfo,
    json_name: "applicationVersion"
  )
end

defmodule Cosmos.Base.Tendermint.V1beta1.VersionInfo do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:name, 1, type: :string)
  field(:app_name, 2, type: :string, json_name: "appName")
  field(:version, 3, type: :string)
  field(:git_commit, 4, type: :string, json_name: "gitCommit")
  field(:build_tags, 5, type: :string, json_name: "buildTags")
  field(:go_version, 6, type: :string, json_name: "goVersion")

  field(:build_deps, 7,
    repeated: true,
    type: Cosmos.Base.Tendermint.V1beta1.Module,
    json_name: "buildDeps"
  )

  field(:cosmos_sdk_version, 8, type: :string, json_name: "cosmosSdkVersion")
end

defmodule Cosmos.Base.Tendermint.V1beta1.Module do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:path, 1, type: :string)
  field(:version, 2, type: :string)
  field(:sum, 3, type: :string)
end

defmodule Cosmos.Base.Tendermint.V1beta1.ABCIQueryRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:data, 1, type: :bytes)
  field(:path, 2, type: :string)
  field(:height, 3, type: :int64)
  field(:prove, 4, type: :bool)
end

defmodule Cosmos.Base.Tendermint.V1beta1.ABCIQueryResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:code, 1, type: :uint32)
  field(:log, 3, type: :string)
  field(:info, 4, type: :string)
  field(:index, 5, type: :int64)
  field(:key, 6, type: :bytes)
  field(:value, 7, type: :bytes)
  field(:proof_ops, 8, type: Cosmos.Base.Tendermint.V1beta1.ProofOps, json_name: "proofOps")
  field(:height, 9, type: :int64)
  field(:codespace, 10, type: :string)
end

defmodule Cosmos.Base.Tendermint.V1beta1.ProofOp do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:type, 1, type: :string)
  field(:key, 2, type: :bytes)
  field(:data, 3, type: :bytes)
end

defmodule Cosmos.Base.Tendermint.V1beta1.ProofOps do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:ops, 1, repeated: true, type: Cosmos.Base.Tendermint.V1beta1.ProofOp, deprecated: false)
end

defmodule Cosmos.Base.Tendermint.V1beta1.Service.Service do
  @moduledoc false

  use GRPC.Service,
    name: "cosmos.base.tendermint.v1beta1.Service",
    protoc_gen_elixir_version: "0.13.0"

  rpc(
    :GetNodeInfo,
    Cosmos.Base.Tendermint.V1beta1.GetNodeInfoRequest,
    Cosmos.Base.Tendermint.V1beta1.GetNodeInfoResponse
  )

  rpc(
    :GetSyncing,
    Cosmos.Base.Tendermint.V1beta1.GetSyncingRequest,
    Cosmos.Base.Tendermint.V1beta1.GetSyncingResponse
  )

  rpc(
    :GetLatestBlock,
    Cosmos.Base.Tendermint.V1beta1.GetLatestBlockRequest,
    Cosmos.Base.Tendermint.V1beta1.GetLatestBlockResponse
  )

  rpc(
    :GetBlockByHeight,
    Cosmos.Base.Tendermint.V1beta1.GetBlockByHeightRequest,
    Cosmos.Base.Tendermint.V1beta1.GetBlockByHeightResponse
  )

  rpc(
    :GetLatestValidatorSet,
    Cosmos.Base.Tendermint.V1beta1.GetLatestValidatorSetRequest,
    Cosmos.Base.Tendermint.V1beta1.GetLatestValidatorSetResponse
  )

  rpc(
    :GetValidatorSetByHeight,
    Cosmos.Base.Tendermint.V1beta1.GetValidatorSetByHeightRequest,
    Cosmos.Base.Tendermint.V1beta1.GetValidatorSetByHeightResponse
  )

  rpc(
    :ABCIQuery,
    Cosmos.Base.Tendermint.V1beta1.ABCIQueryRequest,
    Cosmos.Base.Tendermint.V1beta1.ABCIQueryResponse
  )
end

defmodule Cosmos.Base.Tendermint.V1beta1.Service.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.Base.Tendermint.V1beta1.Service.Service
end
