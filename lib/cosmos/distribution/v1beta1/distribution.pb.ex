defmodule Cosmos.Distribution.V1beta1.Params do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:community_tax, 1, type: :string, json_name: "communityTax", deprecated: false)

  field(:base_proposer_reward, 2,
    type: :string,
    json_name: "baseProposerReward",
    deprecated: true
  )

  field(:bonus_proposer_reward, 3,
    type: :string,
    json_name: "bonusProposerReward",
    deprecated: true
  )

  field(:withdraw_addr_enabled, 4, type: :bool, json_name: "withdrawAddrEnabled")
end

defmodule Cosmos.Distribution.V1beta1.ValidatorHistoricalRewards do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:cumulative_reward_ratio, 1,
    repeated: true,
    type: Cosmos.Base.V1beta1.DecCoin,
    json_name: "cumulativeRewardRatio",
    deprecated: false
  )

  field(:reference_count, 2, type: :uint32, json_name: "referenceCount")
end

defmodule Cosmos.Distribution.V1beta1.ValidatorCurrentRewards do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:rewards, 1, repeated: true, type: Cosmos.Base.V1beta1.DecCoin, deprecated: false)
  field(:period, 2, type: :uint64)
end

defmodule Cosmos.Distribution.V1beta1.ValidatorAccumulatedCommission do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:commission, 1, repeated: true, type: Cosmos.Base.V1beta1.DecCoin, deprecated: false)
end

defmodule Cosmos.Distribution.V1beta1.ValidatorOutstandingRewards do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:rewards, 1, repeated: true, type: Cosmos.Base.V1beta1.DecCoin, deprecated: false)
end

defmodule Cosmos.Distribution.V1beta1.ValidatorSlashEvent do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:validator_period, 1, type: :uint64, json_name: "validatorPeriod")
  field(:fraction, 2, type: :string, deprecated: false)
end

defmodule Cosmos.Distribution.V1beta1.ValidatorSlashEvents do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:validator_slash_events, 1,
    repeated: true,
    type: Cosmos.Distribution.V1beta1.ValidatorSlashEvent,
    json_name: "validatorSlashEvents",
    deprecated: false
  )
end

defmodule Cosmos.Distribution.V1beta1.FeePool do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:community_pool, 1,
    repeated: true,
    type: Cosmos.Base.V1beta1.DecCoin,
    json_name: "communityPool",
    deprecated: false
  )
end

defmodule Cosmos.Distribution.V1beta1.CommunityPoolSpendProposal do
  @moduledoc false

  use Protobuf, deprecated: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:title, 1, type: :string)
  field(:description, 2, type: :string)
  field(:recipient, 3, type: :string)
  field(:amount, 4, repeated: true, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
end

defmodule Cosmos.Distribution.V1beta1.DelegatorStartingInfo do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:previous_period, 1, type: :uint64, json_name: "previousPeriod")
  field(:stake, 2, type: :string, deprecated: false)
  field(:height, 3, type: :uint64, deprecated: false)
end

defmodule Cosmos.Distribution.V1beta1.DelegationDelegatorReward do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:validator_address, 1, type: :string, json_name: "validatorAddress", deprecated: false)
  field(:reward, 2, repeated: true, type: Cosmos.Base.V1beta1.DecCoin, deprecated: false)
end

defmodule Cosmos.Distribution.V1beta1.CommunityPoolSpendProposalWithDeposit do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:title, 1, type: :string)
  field(:description, 2, type: :string)
  field(:recipient, 3, type: :string)
  field(:amount, 4, type: :string)
  field(:deposit, 5, type: :string)
end
