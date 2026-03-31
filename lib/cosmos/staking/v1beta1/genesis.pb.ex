defmodule Cosmos.Staking.V1beta1.GenesisState do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:params, 1, type: Cosmos.Staking.V1beta1.Params, deprecated: false)
  field(:last_total_power, 2, type: :bytes, json_name: "lastTotalPower", deprecated: false)

  field(:last_validator_powers, 3,
    repeated: true,
    type: Cosmos.Staking.V1beta1.LastValidatorPower,
    json_name: "lastValidatorPowers",
    deprecated: false
  )

  field(:validators, 4, repeated: true, type: Cosmos.Staking.V1beta1.Validator, deprecated: false)

  field(:delegations, 5,
    repeated: true,
    type: Cosmos.Staking.V1beta1.Delegation,
    deprecated: false
  )

  field(:unbonding_delegations, 6,
    repeated: true,
    type: Cosmos.Staking.V1beta1.UnbondingDelegation,
    json_name: "unbondingDelegations",
    deprecated: false
  )

  field(:redelegations, 7,
    repeated: true,
    type: Cosmos.Staking.V1beta1.Redelegation,
    deprecated: false
  )

  field(:exported, 8, type: :bool)
end

defmodule Cosmos.Staking.V1beta1.LastValidatorPower do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)
  field(:power, 2, type: :int64)
end
