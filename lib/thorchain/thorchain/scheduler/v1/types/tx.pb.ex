defmodule Thorchain.Thorchain.Scheduler.V1.MsgScheduleExecuteContract do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:sender, 1, type: :string, deprecated: false)
  field(:after, 2, type: :uint64, deprecated: false)
  field(:msg, 3, type: :bytes, deprecated: false)
end

defmodule Thorchain.Thorchain.Scheduler.V1.MsgScheduleExecuteContractResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Thorchain.Thorchain.Scheduler.V1.Msg.Service do
  @moduledoc false

  use GRPC.Service, name: "thorchain.scheduler.v1.Msg", protoc_gen_elixir_version: "0.13.0"

  rpc(
    :ScheduleExecuteContract,
    Thorchain.Thorchain.Scheduler.V1.MsgScheduleExecuteContract,
    Thorchain.Thorchain.Scheduler.V1.MsgScheduleExecuteContractResponse
  )
end

defmodule Thorchain.Thorchain.Scheduler.V1.Msg.Stub do
  @moduledoc false

  use GRPC.Stub, service: Thorchain.Thorchain.Scheduler.V1.Msg.Service
end
