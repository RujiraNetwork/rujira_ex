defmodule Cosmos.Upgrade.V1beta1.QueryCurrentPlanRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Upgrade.V1beta1.QueryCurrentPlanResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:plan, 1, type: Cosmos.Upgrade.V1beta1.Plan)
end

defmodule Cosmos.Upgrade.V1beta1.QueryAppliedPlanRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:name, 1, type: :string)
end

defmodule Cosmos.Upgrade.V1beta1.QueryAppliedPlanResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :int64)
end

defmodule Cosmos.Upgrade.V1beta1.QueryUpgradedConsensusStateRequest do
  @moduledoc false

  use Protobuf, deprecated: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:last_height, 1, type: :int64, json_name: "lastHeight")
end

defmodule Cosmos.Upgrade.V1beta1.QueryUpgradedConsensusStateResponse do
  @moduledoc false

  use Protobuf, deprecated: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:upgraded_consensus_state, 2, type: :bytes, json_name: "upgradedConsensusState")
end

defmodule Cosmos.Upgrade.V1beta1.QueryModuleVersionsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:module_name, 1, type: :string, json_name: "moduleName")
end

defmodule Cosmos.Upgrade.V1beta1.QueryModuleVersionsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:module_versions, 1,
    repeated: true,
    type: Cosmos.Upgrade.V1beta1.ModuleVersion,
    json_name: "moduleVersions"
  )
end

defmodule Cosmos.Upgrade.V1beta1.QueryAuthorityRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Upgrade.V1beta1.QueryAuthorityResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string)
end

defmodule Cosmos.Upgrade.V1beta1.Query.Service do
  @moduledoc false

  use GRPC.Service, name: "cosmos.upgrade.v1beta1.Query", protoc_gen_elixir_version: "0.13.0"

  rpc(
    :CurrentPlan,
    Cosmos.Upgrade.V1beta1.QueryCurrentPlanRequest,
    Cosmos.Upgrade.V1beta1.QueryCurrentPlanResponse
  )

  rpc(
    :AppliedPlan,
    Cosmos.Upgrade.V1beta1.QueryAppliedPlanRequest,
    Cosmos.Upgrade.V1beta1.QueryAppliedPlanResponse
  )

  rpc(
    :UpgradedConsensusState,
    Cosmos.Upgrade.V1beta1.QueryUpgradedConsensusStateRequest,
    Cosmos.Upgrade.V1beta1.QueryUpgradedConsensusStateResponse
  )

  rpc(
    :ModuleVersions,
    Cosmos.Upgrade.V1beta1.QueryModuleVersionsRequest,
    Cosmos.Upgrade.V1beta1.QueryModuleVersionsResponse
  )

  rpc(
    :Authority,
    Cosmos.Upgrade.V1beta1.QueryAuthorityRequest,
    Cosmos.Upgrade.V1beta1.QueryAuthorityResponse
  )
end

defmodule Cosmos.Upgrade.V1beta1.Query.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.Upgrade.V1beta1.Query.Service
end
