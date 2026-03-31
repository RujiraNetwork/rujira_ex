defmodule Cosmos.Staking.V1beta1.QueryValidatorsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:status, 1, type: :string)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Staking.V1beta1.QueryValidatorsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:validators, 1, repeated: true, type: Cosmos.Staking.V1beta1.Validator, deprecated: false)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Staking.V1beta1.QueryValidatorRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:validator_addr, 1, type: :string, json_name: "validatorAddr", deprecated: false)
end

defmodule Cosmos.Staking.V1beta1.QueryValidatorResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:validator, 1, type: Cosmos.Staking.V1beta1.Validator, deprecated: false)
end

defmodule Cosmos.Staking.V1beta1.QueryValidatorDelegationsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:validator_addr, 1, type: :string, json_name: "validatorAddr", deprecated: false)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Staking.V1beta1.QueryValidatorDelegationsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:delegation_responses, 1,
    repeated: true,
    type: Cosmos.Staking.V1beta1.DelegationResponse,
    json_name: "delegationResponses",
    deprecated: false
  )

  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Staking.V1beta1.QueryValidatorUnbondingDelegationsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:validator_addr, 1, type: :string, json_name: "validatorAddr", deprecated: false)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Staking.V1beta1.QueryValidatorUnbondingDelegationsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:unbonding_responses, 1,
    repeated: true,
    type: Cosmos.Staking.V1beta1.UnbondingDelegation,
    json_name: "unbondingResponses",
    deprecated: false
  )

  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Staking.V1beta1.QueryDelegationRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:delegator_addr, 1, type: :string, json_name: "delegatorAddr", deprecated: false)
  field(:validator_addr, 2, type: :string, json_name: "validatorAddr", deprecated: false)
end

defmodule Cosmos.Staking.V1beta1.QueryDelegationResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:delegation_response, 1,
    type: Cosmos.Staking.V1beta1.DelegationResponse,
    json_name: "delegationResponse"
  )
end

defmodule Cosmos.Staking.V1beta1.QueryUnbondingDelegationRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:delegator_addr, 1, type: :string, json_name: "delegatorAddr", deprecated: false)
  field(:validator_addr, 2, type: :string, json_name: "validatorAddr", deprecated: false)
end

defmodule Cosmos.Staking.V1beta1.QueryUnbondingDelegationResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:unbond, 1, type: Cosmos.Staking.V1beta1.UnbondingDelegation, deprecated: false)
end

defmodule Cosmos.Staking.V1beta1.QueryDelegatorDelegationsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:delegator_addr, 1, type: :string, json_name: "delegatorAddr", deprecated: false)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Staking.V1beta1.QueryDelegatorDelegationsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:delegation_responses, 1,
    repeated: true,
    type: Cosmos.Staking.V1beta1.DelegationResponse,
    json_name: "delegationResponses",
    deprecated: false
  )

  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Staking.V1beta1.QueryDelegatorUnbondingDelegationsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:delegator_addr, 1, type: :string, json_name: "delegatorAddr", deprecated: false)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Staking.V1beta1.QueryDelegatorUnbondingDelegationsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:unbonding_responses, 1,
    repeated: true,
    type: Cosmos.Staking.V1beta1.UnbondingDelegation,
    json_name: "unbondingResponses",
    deprecated: false
  )

  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Staking.V1beta1.QueryRedelegationsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:delegator_addr, 1, type: :string, json_name: "delegatorAddr", deprecated: false)
  field(:src_validator_addr, 2, type: :string, json_name: "srcValidatorAddr", deprecated: false)
  field(:dst_validator_addr, 3, type: :string, json_name: "dstValidatorAddr", deprecated: false)
  field(:pagination, 4, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Staking.V1beta1.QueryRedelegationsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:redelegation_responses, 1,
    repeated: true,
    type: Cosmos.Staking.V1beta1.RedelegationResponse,
    json_name: "redelegationResponses",
    deprecated: false
  )

  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Staking.V1beta1.QueryDelegatorValidatorsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:delegator_addr, 1, type: :string, json_name: "delegatorAddr", deprecated: false)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Staking.V1beta1.QueryDelegatorValidatorsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:validators, 1, repeated: true, type: Cosmos.Staking.V1beta1.Validator, deprecated: false)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Staking.V1beta1.QueryDelegatorValidatorRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:delegator_addr, 1, type: :string, json_name: "delegatorAddr", deprecated: false)
  field(:validator_addr, 2, type: :string, json_name: "validatorAddr", deprecated: false)
end

defmodule Cosmos.Staking.V1beta1.QueryDelegatorValidatorResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:validator, 1, type: Cosmos.Staking.V1beta1.Validator, deprecated: false)
end

defmodule Cosmos.Staking.V1beta1.QueryHistoricalInfoRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :int64)
end

defmodule Cosmos.Staking.V1beta1.QueryHistoricalInfoResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:hist, 1, type: Cosmos.Staking.V1beta1.HistoricalInfo)
end

defmodule Cosmos.Staking.V1beta1.QueryPoolRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Staking.V1beta1.QueryPoolResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pool, 1, type: Cosmos.Staking.V1beta1.Pool, deprecated: false)
end

defmodule Cosmos.Staking.V1beta1.QueryParamsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Staking.V1beta1.QueryParamsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:params, 1, type: Cosmos.Staking.V1beta1.Params, deprecated: false)
end

defmodule Cosmos.Staking.V1beta1.Query.Service do
  @moduledoc false

  use GRPC.Service, name: "cosmos.staking.v1beta1.Query", protoc_gen_elixir_version: "0.13.0"

  rpc(
    :Validators,
    Cosmos.Staking.V1beta1.QueryValidatorsRequest,
    Cosmos.Staking.V1beta1.QueryValidatorsResponse
  )

  rpc(
    :Validator,
    Cosmos.Staking.V1beta1.QueryValidatorRequest,
    Cosmos.Staking.V1beta1.QueryValidatorResponse
  )

  rpc(
    :ValidatorDelegations,
    Cosmos.Staking.V1beta1.QueryValidatorDelegationsRequest,
    Cosmos.Staking.V1beta1.QueryValidatorDelegationsResponse
  )

  rpc(
    :ValidatorUnbondingDelegations,
    Cosmos.Staking.V1beta1.QueryValidatorUnbondingDelegationsRequest,
    Cosmos.Staking.V1beta1.QueryValidatorUnbondingDelegationsResponse
  )

  rpc(
    :Delegation,
    Cosmos.Staking.V1beta1.QueryDelegationRequest,
    Cosmos.Staking.V1beta1.QueryDelegationResponse
  )

  rpc(
    :UnbondingDelegation,
    Cosmos.Staking.V1beta1.QueryUnbondingDelegationRequest,
    Cosmos.Staking.V1beta1.QueryUnbondingDelegationResponse
  )

  rpc(
    :DelegatorDelegations,
    Cosmos.Staking.V1beta1.QueryDelegatorDelegationsRequest,
    Cosmos.Staking.V1beta1.QueryDelegatorDelegationsResponse
  )

  rpc(
    :DelegatorUnbondingDelegations,
    Cosmos.Staking.V1beta1.QueryDelegatorUnbondingDelegationsRequest,
    Cosmos.Staking.V1beta1.QueryDelegatorUnbondingDelegationsResponse
  )

  rpc(
    :Redelegations,
    Cosmos.Staking.V1beta1.QueryRedelegationsRequest,
    Cosmos.Staking.V1beta1.QueryRedelegationsResponse
  )

  rpc(
    :DelegatorValidators,
    Cosmos.Staking.V1beta1.QueryDelegatorValidatorsRequest,
    Cosmos.Staking.V1beta1.QueryDelegatorValidatorsResponse
  )

  rpc(
    :DelegatorValidator,
    Cosmos.Staking.V1beta1.QueryDelegatorValidatorRequest,
    Cosmos.Staking.V1beta1.QueryDelegatorValidatorResponse
  )

  rpc(
    :HistoricalInfo,
    Cosmos.Staking.V1beta1.QueryHistoricalInfoRequest,
    Cosmos.Staking.V1beta1.QueryHistoricalInfoResponse
  )

  rpc(:Pool, Cosmos.Staking.V1beta1.QueryPoolRequest, Cosmos.Staking.V1beta1.QueryPoolResponse)

  rpc(
    :Params,
    Cosmos.Staking.V1beta1.QueryParamsRequest,
    Cosmos.Staking.V1beta1.QueryParamsResponse
  )
end

defmodule Cosmos.Staking.V1beta1.Query.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.Staking.V1beta1.Query.Service
end
