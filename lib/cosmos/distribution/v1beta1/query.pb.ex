defmodule Cosmos.Distribution.V1beta1.QueryParamsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Distribution.V1beta1.QueryParamsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:params, 1, type: Cosmos.Distribution.V1beta1.Params, deprecated: false)
end

defmodule Cosmos.Distribution.V1beta1.QueryValidatorDistributionInfoRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:validator_address, 1, type: :string, json_name: "validatorAddress", deprecated: false)
end

defmodule Cosmos.Distribution.V1beta1.QueryValidatorDistributionInfoResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:operator_address, 1, type: :string, json_name: "operatorAddress", deprecated: false)

  field(:self_bond_rewards, 2,
    repeated: true,
    type: Cosmos.Base.V1beta1.DecCoin,
    json_name: "selfBondRewards",
    deprecated: false
  )

  field(:commission, 3, repeated: true, type: Cosmos.Base.V1beta1.DecCoin, deprecated: false)
end

defmodule Cosmos.Distribution.V1beta1.QueryValidatorOutstandingRewardsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:validator_address, 1, type: :string, json_name: "validatorAddress", deprecated: false)
end

defmodule Cosmos.Distribution.V1beta1.QueryValidatorOutstandingRewardsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:rewards, 1,
    type: Cosmos.Distribution.V1beta1.ValidatorOutstandingRewards,
    deprecated: false
  )
end

defmodule Cosmos.Distribution.V1beta1.QueryValidatorCommissionRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:validator_address, 1, type: :string, json_name: "validatorAddress", deprecated: false)
end

defmodule Cosmos.Distribution.V1beta1.QueryValidatorCommissionResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:commission, 1,
    type: Cosmos.Distribution.V1beta1.ValidatorAccumulatedCommission,
    deprecated: false
  )
end

defmodule Cosmos.Distribution.V1beta1.QueryValidatorSlashesRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:validator_address, 1, type: :string, json_name: "validatorAddress", deprecated: false)
  field(:starting_height, 2, type: :uint64, json_name: "startingHeight")
  field(:ending_height, 3, type: :uint64, json_name: "endingHeight")
  field(:pagination, 4, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Distribution.V1beta1.QueryValidatorSlashesResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:slashes, 1,
    repeated: true,
    type: Cosmos.Distribution.V1beta1.ValidatorSlashEvent,
    deprecated: false
  )

  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Distribution.V1beta1.QueryDelegationRewardsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:delegator_address, 1, type: :string, json_name: "delegatorAddress", deprecated: false)
  field(:validator_address, 2, type: :string, json_name: "validatorAddress", deprecated: false)
end

defmodule Cosmos.Distribution.V1beta1.QueryDelegationRewardsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:rewards, 1, repeated: true, type: Cosmos.Base.V1beta1.DecCoin, deprecated: false)
end

defmodule Cosmos.Distribution.V1beta1.QueryDelegationTotalRewardsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:delegator_address, 1, type: :string, json_name: "delegatorAddress", deprecated: false)
end

defmodule Cosmos.Distribution.V1beta1.QueryDelegationTotalRewardsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:rewards, 1,
    repeated: true,
    type: Cosmos.Distribution.V1beta1.DelegationDelegatorReward,
    deprecated: false
  )

  field(:total, 2, repeated: true, type: Cosmos.Base.V1beta1.DecCoin, deprecated: false)
end

defmodule Cosmos.Distribution.V1beta1.QueryDelegatorValidatorsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:delegator_address, 1, type: :string, json_name: "delegatorAddress", deprecated: false)
end

defmodule Cosmos.Distribution.V1beta1.QueryDelegatorValidatorsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:validators, 1, repeated: true, type: :string)
end

defmodule Cosmos.Distribution.V1beta1.QueryDelegatorWithdrawAddressRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:delegator_address, 1, type: :string, json_name: "delegatorAddress", deprecated: false)
end

defmodule Cosmos.Distribution.V1beta1.QueryDelegatorWithdrawAddressResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:withdraw_address, 1, type: :string, json_name: "withdrawAddress", deprecated: false)
end

defmodule Cosmos.Distribution.V1beta1.QueryCommunityPoolRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Distribution.V1beta1.QueryCommunityPoolResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pool, 1, repeated: true, type: Cosmos.Base.V1beta1.DecCoin, deprecated: false)
end

defmodule Cosmos.Distribution.V1beta1.Query.Service do
  @moduledoc false

  use GRPC.Service, name: "cosmos.distribution.v1beta1.Query", protoc_gen_elixir_version: "0.13.0"

  rpc(
    :Params,
    Cosmos.Distribution.V1beta1.QueryParamsRequest,
    Cosmos.Distribution.V1beta1.QueryParamsResponse
  )

  rpc(
    :ValidatorDistributionInfo,
    Cosmos.Distribution.V1beta1.QueryValidatorDistributionInfoRequest,
    Cosmos.Distribution.V1beta1.QueryValidatorDistributionInfoResponse
  )

  rpc(
    :ValidatorOutstandingRewards,
    Cosmos.Distribution.V1beta1.QueryValidatorOutstandingRewardsRequest,
    Cosmos.Distribution.V1beta1.QueryValidatorOutstandingRewardsResponse
  )

  rpc(
    :ValidatorCommission,
    Cosmos.Distribution.V1beta1.QueryValidatorCommissionRequest,
    Cosmos.Distribution.V1beta1.QueryValidatorCommissionResponse
  )

  rpc(
    :ValidatorSlashes,
    Cosmos.Distribution.V1beta1.QueryValidatorSlashesRequest,
    Cosmos.Distribution.V1beta1.QueryValidatorSlashesResponse
  )

  rpc(
    :DelegationRewards,
    Cosmos.Distribution.V1beta1.QueryDelegationRewardsRequest,
    Cosmos.Distribution.V1beta1.QueryDelegationRewardsResponse
  )

  rpc(
    :DelegationTotalRewards,
    Cosmos.Distribution.V1beta1.QueryDelegationTotalRewardsRequest,
    Cosmos.Distribution.V1beta1.QueryDelegationTotalRewardsResponse
  )

  rpc(
    :DelegatorValidators,
    Cosmos.Distribution.V1beta1.QueryDelegatorValidatorsRequest,
    Cosmos.Distribution.V1beta1.QueryDelegatorValidatorsResponse
  )

  rpc(
    :DelegatorWithdrawAddress,
    Cosmos.Distribution.V1beta1.QueryDelegatorWithdrawAddressRequest,
    Cosmos.Distribution.V1beta1.QueryDelegatorWithdrawAddressResponse
  )

  rpc(
    :CommunityPool,
    Cosmos.Distribution.V1beta1.QueryCommunityPoolRequest,
    Cosmos.Distribution.V1beta1.QueryCommunityPoolResponse
  )
end

defmodule Cosmos.Distribution.V1beta1.Query.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.Distribution.V1beta1.Query.Service
end
