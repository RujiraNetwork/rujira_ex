defmodule Cosmos.Vesting.V1beta1.MsgCreateVestingAccount do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:from_address, 1, type: :string, json_name: "fromAddress", deprecated: false)
  field(:to_address, 2, type: :string, json_name: "toAddress", deprecated: false)
  field(:amount, 3, repeated: true, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
  field(:end_time, 4, type: :int64, json_name: "endTime")
  field(:delayed, 5, type: :bool)
end

defmodule Cosmos.Vesting.V1beta1.MsgCreateVestingAccountResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Vesting.V1beta1.MsgCreatePermanentLockedAccount do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:from_address, 1, type: :string, json_name: "fromAddress", deprecated: false)
  field(:to_address, 2, type: :string, json_name: "toAddress", deprecated: false)
  field(:amount, 3, repeated: true, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
end

defmodule Cosmos.Vesting.V1beta1.MsgCreatePermanentLockedAccountResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Vesting.V1beta1.MsgCreatePeriodicVestingAccount do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:from_address, 1, type: :string, json_name: "fromAddress")
  field(:to_address, 2, type: :string, json_name: "toAddress")
  field(:start_time, 3, type: :int64, json_name: "startTime")

  field(:vesting_periods, 4,
    repeated: true,
    type: Cosmos.Vesting.V1beta1.Period,
    json_name: "vestingPeriods",
    deprecated: false
  )
end

defmodule Cosmos.Vesting.V1beta1.MsgCreatePeriodicVestingAccountResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Vesting.V1beta1.Msg.Service do
  @moduledoc false

  use GRPC.Service, name: "cosmos.vesting.v1beta1.Msg", protoc_gen_elixir_version: "0.13.0"

  rpc(
    :CreateVestingAccount,
    Cosmos.Vesting.V1beta1.MsgCreateVestingAccount,
    Cosmos.Vesting.V1beta1.MsgCreateVestingAccountResponse
  )

  rpc(
    :CreatePermanentLockedAccount,
    Cosmos.Vesting.V1beta1.MsgCreatePermanentLockedAccount,
    Cosmos.Vesting.V1beta1.MsgCreatePermanentLockedAccountResponse
  )

  rpc(
    :CreatePeriodicVestingAccount,
    Cosmos.Vesting.V1beta1.MsgCreatePeriodicVestingAccount,
    Cosmos.Vesting.V1beta1.MsgCreatePeriodicVestingAccountResponse
  )
end

defmodule Cosmos.Vesting.V1beta1.Msg.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.Vesting.V1beta1.Msg.Service
end
