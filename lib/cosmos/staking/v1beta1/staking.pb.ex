defmodule Cosmos.Staking.V1beta1.BondStatus do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:BOND_STATUS_UNSPECIFIED, 0)
  field(:BOND_STATUS_UNBONDED, 1)
  field(:BOND_STATUS_UNBONDING, 2)
  field(:BOND_STATUS_BONDED, 3)
end

defmodule Cosmos.Staking.V1beta1.Infraction do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:INFRACTION_UNSPECIFIED, 0)
  field(:INFRACTION_DOUBLE_SIGN, 1)
  field(:INFRACTION_DOWNTIME, 2)
end

defmodule Cosmos.Staking.V1beta1.HistoricalInfo do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:header, 1, type: Tendermint.Types.Header, deprecated: false)
  field(:valset, 2, repeated: true, type: Cosmos.Staking.V1beta1.Validator, deprecated: false)
end

defmodule Cosmos.Staking.V1beta1.CommissionRates do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:rate, 1, type: :string, deprecated: false)
  field(:max_rate, 2, type: :string, json_name: "maxRate", deprecated: false)
  field(:max_change_rate, 3, type: :string, json_name: "maxChangeRate", deprecated: false)
end

defmodule Cosmos.Staking.V1beta1.Commission do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:commission_rates, 1,
    type: Cosmos.Staking.V1beta1.CommissionRates,
    json_name: "commissionRates",
    deprecated: false
  )

  field(:update_time, 2,
    type: Google.Protobuf.Timestamp,
    json_name: "updateTime",
    deprecated: false
  )
end

defmodule Cosmos.Staking.V1beta1.Description do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:moniker, 1, type: :string)
  field(:identity, 2, type: :string)
  field(:website, 3, type: :string)
  field(:security_contact, 4, type: :string, json_name: "securityContact")
  field(:details, 5, type: :string)
end

defmodule Cosmos.Staking.V1beta1.Validator do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:operator_address, 1, type: :string, json_name: "operatorAddress", deprecated: false)

  field(:consensus_pubkey, 2,
    type: Google.Protobuf.Any,
    json_name: "consensusPubkey",
    deprecated: false
  )

  field(:jailed, 3, type: :bool)
  field(:status, 4, type: Cosmos.Staking.V1beta1.BondStatus, enum: true)
  field(:tokens, 5, type: :string, deprecated: false)
  field(:delegator_shares, 6, type: :string, json_name: "delegatorShares", deprecated: false)
  field(:description, 7, type: Cosmos.Staking.V1beta1.Description, deprecated: false)
  field(:unbonding_height, 8, type: :int64, json_name: "unbondingHeight")

  field(:unbonding_time, 9,
    type: Google.Protobuf.Timestamp,
    json_name: "unbondingTime",
    deprecated: false
  )

  field(:commission, 10, type: Cosmos.Staking.V1beta1.Commission, deprecated: false)

  field(:min_self_delegation, 11,
    type: :string,
    json_name: "minSelfDelegation",
    deprecated: false
  )

  field(:unbonding_on_hold_ref_count, 12, type: :int64, json_name: "unbondingOnHoldRefCount")
  field(:unbonding_ids, 13, repeated: true, type: :uint64, json_name: "unbondingIds")
end

defmodule Cosmos.Staking.V1beta1.ValAddresses do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:addresses, 1, repeated: true, type: :string, deprecated: false)
end

defmodule Cosmos.Staking.V1beta1.DVPair do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:delegator_address, 1, type: :string, json_name: "delegatorAddress", deprecated: false)
  field(:validator_address, 2, type: :string, json_name: "validatorAddress", deprecated: false)
end

defmodule Cosmos.Staking.V1beta1.DVPairs do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pairs, 1, repeated: true, type: Cosmos.Staking.V1beta1.DVPair, deprecated: false)
end

defmodule Cosmos.Staking.V1beta1.DVVTriplet do
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
end

defmodule Cosmos.Staking.V1beta1.DVVTriplets do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:triplets, 1, repeated: true, type: Cosmos.Staking.V1beta1.DVVTriplet, deprecated: false)
end

defmodule Cosmos.Staking.V1beta1.Delegation do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:delegator_address, 1, type: :string, json_name: "delegatorAddress", deprecated: false)
  field(:validator_address, 2, type: :string, json_name: "validatorAddress", deprecated: false)
  field(:shares, 3, type: :string, deprecated: false)
end

defmodule Cosmos.Staking.V1beta1.UnbondingDelegation do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:delegator_address, 1, type: :string, json_name: "delegatorAddress", deprecated: false)
  field(:validator_address, 2, type: :string, json_name: "validatorAddress", deprecated: false)

  field(:entries, 3,
    repeated: true,
    type: Cosmos.Staking.V1beta1.UnbondingDelegationEntry,
    deprecated: false
  )
end

defmodule Cosmos.Staking.V1beta1.UnbondingDelegationEntry do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:creation_height, 1, type: :int64, json_name: "creationHeight")

  field(:completion_time, 2,
    type: Google.Protobuf.Timestamp,
    json_name: "completionTime",
    deprecated: false
  )

  field(:initial_balance, 3, type: :string, json_name: "initialBalance", deprecated: false)
  field(:balance, 4, type: :string, deprecated: false)
  field(:unbonding_id, 5, type: :uint64, json_name: "unbondingId")
  field(:unbonding_on_hold_ref_count, 6, type: :int64, json_name: "unbondingOnHoldRefCount")
end

defmodule Cosmos.Staking.V1beta1.RedelegationEntry do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:creation_height, 1, type: :int64, json_name: "creationHeight")

  field(:completion_time, 2,
    type: Google.Protobuf.Timestamp,
    json_name: "completionTime",
    deprecated: false
  )

  field(:initial_balance, 3, type: :string, json_name: "initialBalance", deprecated: false)
  field(:shares_dst, 4, type: :string, json_name: "sharesDst", deprecated: false)
  field(:unbonding_id, 5, type: :uint64, json_name: "unbondingId")
  field(:unbonding_on_hold_ref_count, 6, type: :int64, json_name: "unbondingOnHoldRefCount")
end

defmodule Cosmos.Staking.V1beta1.Redelegation do
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

  field(:entries, 4,
    repeated: true,
    type: Cosmos.Staking.V1beta1.RedelegationEntry,
    deprecated: false
  )
end

defmodule Cosmos.Staking.V1beta1.Params do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:unbonding_time, 1,
    type: Google.Protobuf.Duration,
    json_name: "unbondingTime",
    deprecated: false
  )

  field(:max_validators, 2, type: :uint32, json_name: "maxValidators")
  field(:max_entries, 3, type: :uint32, json_name: "maxEntries")
  field(:historical_entries, 4, type: :uint32, json_name: "historicalEntries")
  field(:bond_denom, 5, type: :string, json_name: "bondDenom")
  field(:min_commission_rate, 6, type: :string, json_name: "minCommissionRate", deprecated: false)
end

defmodule Cosmos.Staking.V1beta1.DelegationResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:delegation, 1, type: Cosmos.Staking.V1beta1.Delegation, deprecated: false)
  field(:balance, 2, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
end

defmodule Cosmos.Staking.V1beta1.RedelegationEntryResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:redelegation_entry, 1,
    type: Cosmos.Staking.V1beta1.RedelegationEntry,
    json_name: "redelegationEntry",
    deprecated: false
  )

  field(:balance, 4, type: :string, deprecated: false)
end

defmodule Cosmos.Staking.V1beta1.RedelegationResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:redelegation, 1, type: Cosmos.Staking.V1beta1.Redelegation, deprecated: false)

  field(:entries, 2,
    repeated: true,
    type: Cosmos.Staking.V1beta1.RedelegationEntryResponse,
    deprecated: false
  )
end

defmodule Cosmos.Staking.V1beta1.Pool do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:not_bonded_tokens, 1, type: :string, json_name: "notBondedTokens", deprecated: false)
  field(:bonded_tokens, 2, type: :string, json_name: "bondedTokens", deprecated: false)
end

defmodule Cosmos.Staking.V1beta1.ValidatorUpdates do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:updates, 1, repeated: true, type: Tendermint.Abci.ValidatorUpdate, deprecated: false)
end
