defmodule Cosmos.Vesting.V1beta1.BaseVestingAccount do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:base_account, 1,
    type: Cosmos.Auth.V1beta1.BaseAccount,
    json_name: "baseAccount",
    deprecated: false
  )

  field(:original_vesting, 2,
    repeated: true,
    type: Cosmos.Base.V1beta1.Coin,
    json_name: "originalVesting",
    deprecated: false
  )

  field(:delegated_free, 3,
    repeated: true,
    type: Cosmos.Base.V1beta1.Coin,
    json_name: "delegatedFree",
    deprecated: false
  )

  field(:delegated_vesting, 4,
    repeated: true,
    type: Cosmos.Base.V1beta1.Coin,
    json_name: "delegatedVesting",
    deprecated: false
  )

  field(:end_time, 5, type: :int64, json_name: "endTime")
end

defmodule Cosmos.Vesting.V1beta1.ContinuousVestingAccount do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:base_vesting_account, 1,
    type: Cosmos.Vesting.V1beta1.BaseVestingAccount,
    json_name: "baseVestingAccount",
    deprecated: false
  )

  field(:start_time, 2, type: :int64, json_name: "startTime")
end

defmodule Cosmos.Vesting.V1beta1.DelayedVestingAccount do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:base_vesting_account, 1,
    type: Cosmos.Vesting.V1beta1.BaseVestingAccount,
    json_name: "baseVestingAccount",
    deprecated: false
  )
end

defmodule Cosmos.Vesting.V1beta1.Period do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:length, 1, type: :int64)
  field(:amount, 2, repeated: true, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
end

defmodule Cosmos.Vesting.V1beta1.PeriodicVestingAccount do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:base_vesting_account, 1,
    type: Cosmos.Vesting.V1beta1.BaseVestingAccount,
    json_name: "baseVestingAccount",
    deprecated: false
  )

  field(:start_time, 2, type: :int64, json_name: "startTime")

  field(:vesting_periods, 3,
    repeated: true,
    type: Cosmos.Vesting.V1beta1.Period,
    json_name: "vestingPeriods",
    deprecated: false
  )
end

defmodule Cosmos.Vesting.V1beta1.PermanentLockedAccount do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:base_vesting_account, 1,
    type: Cosmos.Vesting.V1beta1.BaseVestingAccount,
    json_name: "baseVestingAccount",
    deprecated: false
  )
end
