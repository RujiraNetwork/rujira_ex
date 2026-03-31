defmodule Cosmos.Distribution.V1beta1.MsgSetWithdrawAddress do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:delegator_address, 1, type: :string, json_name: "delegatorAddress", deprecated: false)
  field(:withdraw_address, 2, type: :string, json_name: "withdrawAddress", deprecated: false)
end

defmodule Cosmos.Distribution.V1beta1.MsgSetWithdrawAddressResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Distribution.V1beta1.MsgWithdrawDelegatorReward do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:delegator_address, 1, type: :string, json_name: "delegatorAddress", deprecated: false)
  field(:validator_address, 2, type: :string, json_name: "validatorAddress", deprecated: false)
end

defmodule Cosmos.Distribution.V1beta1.MsgWithdrawDelegatorRewardResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:amount, 1, repeated: true, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
end

defmodule Cosmos.Distribution.V1beta1.MsgWithdrawValidatorCommission do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:validator_address, 1, type: :string, json_name: "validatorAddress", deprecated: false)
end

defmodule Cosmos.Distribution.V1beta1.MsgWithdrawValidatorCommissionResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:amount, 1, repeated: true, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
end

defmodule Cosmos.Distribution.V1beta1.MsgFundCommunityPool do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:amount, 1, repeated: true, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
  field(:depositor, 2, type: :string, deprecated: false)
end

defmodule Cosmos.Distribution.V1beta1.MsgFundCommunityPoolResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Distribution.V1beta1.MsgUpdateParams do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:authority, 1, type: :string, deprecated: false)
  field(:params, 2, type: Cosmos.Distribution.V1beta1.Params, deprecated: false)
end

defmodule Cosmos.Distribution.V1beta1.MsgUpdateParamsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Distribution.V1beta1.MsgCommunityPoolSpend do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:authority, 1, type: :string, deprecated: false)
  field(:recipient, 2, type: :string)
  field(:amount, 3, repeated: true, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
end

defmodule Cosmos.Distribution.V1beta1.MsgCommunityPoolSpendResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Distribution.V1beta1.MsgDepositValidatorRewardsPool do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:depositor, 1, type: :string, deprecated: false)
  field(:validator_address, 2, type: :string, json_name: "validatorAddress", deprecated: false)
  field(:amount, 3, repeated: true, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
end

defmodule Cosmos.Distribution.V1beta1.MsgDepositValidatorRewardsPoolResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Distribution.V1beta1.Msg.Service do
  @moduledoc false

  use GRPC.Service, name: "cosmos.distribution.v1beta1.Msg", protoc_gen_elixir_version: "0.13.0"

  rpc(
    :SetWithdrawAddress,
    Cosmos.Distribution.V1beta1.MsgSetWithdrawAddress,
    Cosmos.Distribution.V1beta1.MsgSetWithdrawAddressResponse
  )

  rpc(
    :WithdrawDelegatorReward,
    Cosmos.Distribution.V1beta1.MsgWithdrawDelegatorReward,
    Cosmos.Distribution.V1beta1.MsgWithdrawDelegatorRewardResponse
  )

  rpc(
    :WithdrawValidatorCommission,
    Cosmos.Distribution.V1beta1.MsgWithdrawValidatorCommission,
    Cosmos.Distribution.V1beta1.MsgWithdrawValidatorCommissionResponse
  )

  rpc(
    :FundCommunityPool,
    Cosmos.Distribution.V1beta1.MsgFundCommunityPool,
    Cosmos.Distribution.V1beta1.MsgFundCommunityPoolResponse
  )

  rpc(
    :UpdateParams,
    Cosmos.Distribution.V1beta1.MsgUpdateParams,
    Cosmos.Distribution.V1beta1.MsgUpdateParamsResponse
  )

  rpc(
    :CommunityPoolSpend,
    Cosmos.Distribution.V1beta1.MsgCommunityPoolSpend,
    Cosmos.Distribution.V1beta1.MsgCommunityPoolSpendResponse
  )

  rpc(
    :DepositValidatorRewardsPool,
    Cosmos.Distribution.V1beta1.MsgDepositValidatorRewardsPool,
    Cosmos.Distribution.V1beta1.MsgDepositValidatorRewardsPoolResponse
  )
end

defmodule Cosmos.Distribution.V1beta1.Msg.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.Distribution.V1beta1.Msg.Service
end
