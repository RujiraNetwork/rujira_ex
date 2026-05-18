defmodule Thorchain.Thorchain.Scheduler.V1.QueryScheduleRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :uint64, deprecated: false)
end

defmodule Thorchain.Thorchain.Scheduler.V1.QueryScheduleResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:schedule, 1, type: Thorchain.Thorchain.Scheduler.V1.Schedule, deprecated: false)
end

defmodule Thorchain.Thorchain.Scheduler.V1.QuerySchedulesRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pagination, 1, type: Cosmos.Base.Query.V1beta1.PageRequest, deprecated: false)
  field(:sender, 2, type: :string, deprecated: false)
end

defmodule Thorchain.Thorchain.Scheduler.V1.QuerySchedulesResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:schedules, 1,
    repeated: true,
    type: Thorchain.Thorchain.Scheduler.V1.Schedule,
    deprecated: false
  )

  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse, deprecated: false)
end

defmodule Thorchain.Thorchain.Scheduler.V1.Query.Service do
  @moduledoc false

  use GRPC.Service, name: "thorchain.scheduler.v1.Query", protoc_gen_elixir_version: "0.13.0"

  rpc(
    :Schedule,
    Thorchain.Thorchain.Scheduler.V1.QueryScheduleRequest,
    Thorchain.Thorchain.Scheduler.V1.QueryScheduleResponse
  )

  rpc(
    :Schedules,
    Thorchain.Thorchain.Scheduler.V1.QuerySchedulesRequest,
    Thorchain.Thorchain.Scheduler.V1.QuerySchedulesResponse
  )
end

defmodule Thorchain.Thorchain.Scheduler.V1.Query.Stub do
  @moduledoc false

  use GRPC.Stub, service: Thorchain.Thorchain.Scheduler.V1.Query.Service
end
