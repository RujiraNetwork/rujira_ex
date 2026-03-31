defmodule Cosmos.Staking.V1beta1.AuthorizationType do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:AUTHORIZATION_TYPE_UNSPECIFIED, 0)
  field(:AUTHORIZATION_TYPE_DELEGATE, 1)
  field(:AUTHORIZATION_TYPE_UNDELEGATE, 2)
  field(:AUTHORIZATION_TYPE_REDELEGATE, 3)
  field(:AUTHORIZATION_TYPE_CANCEL_UNBONDING_DELEGATION, 4)
end

defmodule Cosmos.Staking.V1beta1.StakeAuthorization.Validators do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, repeated: true, type: :string, deprecated: false)
end

defmodule Cosmos.Staking.V1beta1.StakeAuthorization do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  oneof(:validators, 0)

  field(:max_tokens, 1, type: Cosmos.Base.V1beta1.Coin, json_name: "maxTokens", deprecated: false)

  field(:allow_list, 2,
    type: Cosmos.Staking.V1beta1.StakeAuthorization.Validators,
    json_name: "allowList",
    oneof: 0,
    deprecated: false
  )

  field(:deny_list, 3,
    type: Cosmos.Staking.V1beta1.StakeAuthorization.Validators,
    json_name: "denyList",
    oneof: 0,
    deprecated: false
  )

  field(:authorization_type, 4,
    type: Cosmos.Staking.V1beta1.AuthorizationType,
    json_name: "authorizationType",
    enum: true
  )
end
