defmodule Cosmos.Distribution.V1beta1.DelegatorWithdrawInfo do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:delegator_address, 1, type: :string, json_name: "delegatorAddress", deprecated: false)
  field(:withdraw_address, 2, type: :string, json_name: "withdrawAddress", deprecated: false)
end

defmodule Cosmos.Distribution.V1beta1.ValidatorOutstandingRewardsRecord do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:validator_address, 1, type: :string, json_name: "validatorAddress", deprecated: false)

  field(:outstanding_rewards, 2,
    repeated: true,
    type: Cosmos.Base.V1beta1.DecCoin,
    json_name: "outstandingRewards",
    deprecated: false
  )
end

defmodule Cosmos.Distribution.V1beta1.ValidatorAccumulatedCommissionRecord do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:validator_address, 1, type: :string, json_name: "validatorAddress", deprecated: false)

  field(:accumulated, 2,
    type: Cosmos.Distribution.V1beta1.ValidatorAccumulatedCommission,
    deprecated: false
  )
end

defmodule Cosmos.Distribution.V1beta1.ValidatorHistoricalRewardsRecord do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:validator_address, 1, type: :string, json_name: "validatorAddress", deprecated: false)
  field(:period, 2, type: :uint64)

  field(:rewards, 3,
    type: Cosmos.Distribution.V1beta1.ValidatorHistoricalRewards,
    deprecated: false
  )
end

defmodule Cosmos.Distribution.V1beta1.ValidatorCurrentRewardsRecord do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:validator_address, 1, type: :string, json_name: "validatorAddress", deprecated: false)
  field(:rewards, 2, type: Cosmos.Distribution.V1beta1.ValidatorCurrentRewards, deprecated: false)
end

defmodule Cosmos.Distribution.V1beta1.DelegatorStartingInfoRecord do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:delegator_address, 1, type: :string, json_name: "delegatorAddress", deprecated: false)
  field(:validator_address, 2, type: :string, json_name: "validatorAddress", deprecated: false)

  field(:starting_info, 3,
    type: Cosmos.Distribution.V1beta1.DelegatorStartingInfo,
    json_name: "startingInfo",
    deprecated: false
  )
end

defmodule Cosmos.Distribution.V1beta1.ValidatorSlashEventRecord do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:validator_address, 1, type: :string, json_name: "validatorAddress", deprecated: false)
  field(:height, 2, type: :uint64)
  field(:period, 3, type: :uint64)

  field(:validator_slash_event, 4,
    type: Cosmos.Distribution.V1beta1.ValidatorSlashEvent,
    json_name: "validatorSlashEvent",
    deprecated: false
  )
end

defmodule Cosmos.Distribution.V1beta1.GenesisState do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:params, 1, type: Cosmos.Distribution.V1beta1.Params, deprecated: false)

  field(:fee_pool, 2,
    type: Cosmos.Distribution.V1beta1.FeePool,
    json_name: "feePool",
    deprecated: false
  )

  field(:delegator_withdraw_infos, 3,
    repeated: true,
    type: Cosmos.Distribution.V1beta1.DelegatorWithdrawInfo,
    json_name: "delegatorWithdrawInfos",
    deprecated: false
  )

  field(:previous_proposer, 4, type: :string, json_name: "previousProposer", deprecated: false)

  field(:outstanding_rewards, 5,
    repeated: true,
    type: Cosmos.Distribution.V1beta1.ValidatorOutstandingRewardsRecord,
    json_name: "outstandingRewards",
    deprecated: false
  )

  field(:validator_accumulated_commissions, 6,
    repeated: true,
    type: Cosmos.Distribution.V1beta1.ValidatorAccumulatedCommissionRecord,
    json_name: "validatorAccumulatedCommissions",
    deprecated: false
  )

  field(:validator_historical_rewards, 7,
    repeated: true,
    type: Cosmos.Distribution.V1beta1.ValidatorHistoricalRewardsRecord,
    json_name: "validatorHistoricalRewards",
    deprecated: false
  )

  field(:validator_current_rewards, 8,
    repeated: true,
    type: Cosmos.Distribution.V1beta1.ValidatorCurrentRewardsRecord,
    json_name: "validatorCurrentRewards",
    deprecated: false
  )

  field(:delegator_starting_infos, 9,
    repeated: true,
    type: Cosmos.Distribution.V1beta1.DelegatorStartingInfoRecord,
    json_name: "delegatorStartingInfos",
    deprecated: false
  )

  field(:validator_slash_events, 10,
    repeated: true,
    type: Cosmos.Distribution.V1beta1.ValidatorSlashEventRecord,
    json_name: "validatorSlashEvents",
    deprecated: false
  )
end
