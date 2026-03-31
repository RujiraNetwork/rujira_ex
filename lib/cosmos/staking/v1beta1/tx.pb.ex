defmodule Cosmos.Staking.V1beta1.MsgCreateValidator do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:description, 1, type: Cosmos.Staking.V1beta1.Description, deprecated: false)
  field(:commission, 2, type: Cosmos.Staking.V1beta1.CommissionRates, deprecated: false)
  field(:min_self_delegation, 3, type: :string, json_name: "minSelfDelegation", deprecated: false)
  field(:delegator_address, 4, type: :string, json_name: "delegatorAddress", deprecated: true)
  field(:validator_address, 5, type: :string, json_name: "validatorAddress", deprecated: false)
  field(:pubkey, 6, type: Google.Protobuf.Any, deprecated: false)
  field(:value, 7, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
end

defmodule Cosmos.Staking.V1beta1.MsgCreateValidatorResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Staking.V1beta1.MsgEditValidator do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:description, 1, type: Cosmos.Staking.V1beta1.Description, deprecated: false)
  field(:validator_address, 2, type: :string, json_name: "validatorAddress", deprecated: false)
  field(:commission_rate, 3, type: :string, json_name: "commissionRate", deprecated: false)
  field(:min_self_delegation, 4, type: :string, json_name: "minSelfDelegation", deprecated: false)
end

defmodule Cosmos.Staking.V1beta1.MsgEditValidatorResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Staking.V1beta1.MsgDelegate do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:delegator_address, 1, type: :string, json_name: "delegatorAddress", deprecated: false)
  field(:validator_address, 2, type: :string, json_name: "validatorAddress", deprecated: false)
  field(:amount, 3, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
end

defmodule Cosmos.Staking.V1beta1.MsgDelegateResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Staking.V1beta1.MsgBeginRedelegate do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:delegator_address, 1, type: :string, json_name: "delegatorAddress", deprecated: false)

  field(:validator_src_address, 2,
    type: :string,
    json_name: "validatorSrcAddress",
    deprecated: false
  )

  field(:validator_dst_address, 3,
    type: :string,
    json_name: "validatorDstAddress",
    deprecated: false
  )

  field(:amount, 4, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
end

defmodule Cosmos.Staking.V1beta1.MsgBeginRedelegateResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:completion_time, 1,
    type: Google.Protobuf.Timestamp,
    json_name: "completionTime",
    deprecated: false
  )
end

defmodule Cosmos.Staking.V1beta1.MsgUndelegate do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:delegator_address, 1, type: :string, json_name: "delegatorAddress", deprecated: false)
  field(:validator_address, 2, type: :string, json_name: "validatorAddress", deprecated: false)
  field(:amount, 3, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
end

defmodule Cosmos.Staking.V1beta1.MsgUndelegateResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:completion_time, 1,
    type: Google.Protobuf.Timestamp,
    json_name: "completionTime",
    deprecated: false
  )

  field(:amount, 2, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
end

defmodule Cosmos.Staking.V1beta1.MsgCancelUnbondingDelegation do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:delegator_address, 1, type: :string, json_name: "delegatorAddress", deprecated: false)
  field(:validator_address, 2, type: :string, json_name: "validatorAddress", deprecated: false)
  field(:amount, 3, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
  field(:creation_height, 4, type: :int64, json_name: "creationHeight")
end

defmodule Cosmos.Staking.V1beta1.MsgCancelUnbondingDelegationResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Staking.V1beta1.MsgUpdateParams do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:authority, 1, type: :string, deprecated: false)
  field(:params, 2, type: Cosmos.Staking.V1beta1.Params, deprecated: false)
end

defmodule Cosmos.Staking.V1beta1.MsgUpdateParamsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Staking.V1beta1.Msg.Service do
  @moduledoc false

  use GRPC.Service, name: "cosmos.staking.v1beta1.Msg", protoc_gen_elixir_version: "0.13.0"

  rpc(
    :CreateValidator,
    Cosmos.Staking.V1beta1.MsgCreateValidator,
    Cosmos.Staking.V1beta1.MsgCreateValidatorResponse
  )

  rpc(
    :EditValidator,
    Cosmos.Staking.V1beta1.MsgEditValidator,
    Cosmos.Staking.V1beta1.MsgEditValidatorResponse
  )

  rpc(:Delegate, Cosmos.Staking.V1beta1.MsgDelegate, Cosmos.Staking.V1beta1.MsgDelegateResponse)

  rpc(
    :BeginRedelegate,
    Cosmos.Staking.V1beta1.MsgBeginRedelegate,
    Cosmos.Staking.V1beta1.MsgBeginRedelegateResponse
  )

  rpc(
    :Undelegate,
    Cosmos.Staking.V1beta1.MsgUndelegate,
    Cosmos.Staking.V1beta1.MsgUndelegateResponse
  )

  rpc(
    :CancelUnbondingDelegation,
    Cosmos.Staking.V1beta1.MsgCancelUnbondingDelegation,
    Cosmos.Staking.V1beta1.MsgCancelUnbondingDelegationResponse
  )

  rpc(
    :UpdateParams,
    Cosmos.Staking.V1beta1.MsgUpdateParams,
    Cosmos.Staking.V1beta1.MsgUpdateParamsResponse
  )
end

defmodule Cosmos.Staking.V1beta1.Msg.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.Staking.V1beta1.Msg.Service
end
