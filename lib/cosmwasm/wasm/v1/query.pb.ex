defmodule Cosmwasm.Wasm.V1.QueryContractInfoRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)
end

defmodule Cosmwasm.Wasm.V1.QueryContractInfoResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)

  field(:contract_info, 2,
    type: Cosmwasm.Wasm.V1.ContractInfo,
    json_name: "contractInfo",
    deprecated: false
  )
end

defmodule Cosmwasm.Wasm.V1.QueryContractHistoryRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmwasm.Wasm.V1.QueryContractHistoryResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:entries, 1,
    repeated: true,
    type: Cosmwasm.Wasm.V1.ContractCodeHistoryEntry,
    deprecated: false
  )

  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmwasm.Wasm.V1.QueryContractsByCodeRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:code_id, 1, type: :uint64, json_name: "codeId")
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmwasm.Wasm.V1.QueryContractsByCodeResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:contracts, 1, repeated: true, type: :string, deprecated: false)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmwasm.Wasm.V1.QueryAllContractStateRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmwasm.Wasm.V1.QueryAllContractStateResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:models, 1, repeated: true, type: Cosmwasm.Wasm.V1.Model, deprecated: false)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmwasm.Wasm.V1.QueryRawContractStateRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)
  field(:query_data, 2, type: :bytes, json_name: "queryData")
end

defmodule Cosmwasm.Wasm.V1.QueryRawContractStateResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:data, 1, type: :bytes)
end

defmodule Cosmwasm.Wasm.V1.QuerySmartContractStateRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)
  field(:query_data, 2, type: :bytes, json_name: "queryData", deprecated: false)
end

defmodule Cosmwasm.Wasm.V1.QuerySmartContractStateResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:data, 1, type: :bytes, deprecated: false)
end

defmodule Cosmwasm.Wasm.V1.QueryCodeRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:code_id, 1, type: :uint64, json_name: "codeId")
end

defmodule Cosmwasm.Wasm.V1.CodeInfoResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:code_id, 1, type: :uint64, json_name: "codeId", deprecated: false)
  field(:creator, 2, type: :string, deprecated: false)
  field(:data_hash, 3, type: :bytes, json_name: "dataHash", deprecated: false)

  field(:instantiate_permission, 6,
    type: Cosmwasm.Wasm.V1.AccessConfig,
    json_name: "instantiatePermission",
    deprecated: false
  )
end

defmodule Cosmwasm.Wasm.V1.QueryCodeResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:code_info, 1,
    type: Cosmwasm.Wasm.V1.CodeInfoResponse,
    json_name: "codeInfo",
    deprecated: false
  )

  field(:data, 2, type: :bytes, deprecated: false)
end

defmodule Cosmwasm.Wasm.V1.QueryCodesRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pagination, 1, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmwasm.Wasm.V1.QueryCodesResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:code_infos, 1,
    repeated: true,
    type: Cosmwasm.Wasm.V1.CodeInfoResponse,
    json_name: "codeInfos",
    deprecated: false
  )

  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmwasm.Wasm.V1.QueryPinnedCodesRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmwasm.Wasm.V1.QueryPinnedCodesResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:code_ids, 1, repeated: true, type: :uint64, json_name: "codeIds", deprecated: false)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmwasm.Wasm.V1.QueryParamsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmwasm.Wasm.V1.QueryParamsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:params, 1, type: Cosmwasm.Wasm.V1.Params, deprecated: false)
end

defmodule Cosmwasm.Wasm.V1.QueryContractsByCreatorRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:creator_address, 1, type: :string, json_name: "creatorAddress", deprecated: false)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmwasm.Wasm.V1.QueryContractsByCreatorResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:contract_addresses, 1,
    repeated: true,
    type: :string,
    json_name: "contractAddresses",
    deprecated: false
  )

  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmwasm.Wasm.V1.QueryBuildAddressRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:code_hash, 1, type: :string, json_name: "codeHash")
  field(:creator_address, 2, type: :string, json_name: "creatorAddress", deprecated: false)
  field(:salt, 3, type: :string)
  field(:init_args, 4, type: :bytes, json_name: "initArgs")
end

defmodule Cosmwasm.Wasm.V1.QueryBuildAddressResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)
end

defmodule Cosmwasm.Wasm.V1.Query.Service do
  @moduledoc false

  use GRPC.Service, name: "cosmwasm.wasm.v1.Query", protoc_gen_elixir_version: "0.13.0"

  rpc(
    :ContractInfo,
    Cosmwasm.Wasm.V1.QueryContractInfoRequest,
    Cosmwasm.Wasm.V1.QueryContractInfoResponse
  )

  rpc(
    :ContractHistory,
    Cosmwasm.Wasm.V1.QueryContractHistoryRequest,
    Cosmwasm.Wasm.V1.QueryContractHistoryResponse
  )

  rpc(
    :ContractsByCode,
    Cosmwasm.Wasm.V1.QueryContractsByCodeRequest,
    Cosmwasm.Wasm.V1.QueryContractsByCodeResponse
  )

  rpc(
    :AllContractState,
    Cosmwasm.Wasm.V1.QueryAllContractStateRequest,
    Cosmwasm.Wasm.V1.QueryAllContractStateResponse
  )

  rpc(
    :RawContractState,
    Cosmwasm.Wasm.V1.QueryRawContractStateRequest,
    Cosmwasm.Wasm.V1.QueryRawContractStateResponse
  )

  rpc(
    :SmartContractState,
    Cosmwasm.Wasm.V1.QuerySmartContractStateRequest,
    Cosmwasm.Wasm.V1.QuerySmartContractStateResponse
  )

  rpc(:Code, Cosmwasm.Wasm.V1.QueryCodeRequest, Cosmwasm.Wasm.V1.QueryCodeResponse)

  rpc(:Codes, Cosmwasm.Wasm.V1.QueryCodesRequest, Cosmwasm.Wasm.V1.QueryCodesResponse)

  rpc(
    :PinnedCodes,
    Cosmwasm.Wasm.V1.QueryPinnedCodesRequest,
    Cosmwasm.Wasm.V1.QueryPinnedCodesResponse
  )

  rpc(:Params, Cosmwasm.Wasm.V1.QueryParamsRequest, Cosmwasm.Wasm.V1.QueryParamsResponse)

  rpc(
    :ContractsByCreator,
    Cosmwasm.Wasm.V1.QueryContractsByCreatorRequest,
    Cosmwasm.Wasm.V1.QueryContractsByCreatorResponse
  )

  rpc(
    :BuildAddress,
    Cosmwasm.Wasm.V1.QueryBuildAddressRequest,
    Cosmwasm.Wasm.V1.QueryBuildAddressResponse
  )
end

defmodule Cosmwasm.Wasm.V1.Query.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmwasm.Wasm.V1.Query.Service
end
