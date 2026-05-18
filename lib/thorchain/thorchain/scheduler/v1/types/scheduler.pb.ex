defmodule Thorchain.Thorchain.Scheduler.V1.Schedule do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :uint64, deprecated: false)

  field(:msgs, 2,
    repeated: true,
    type: Thorchain.Thorchain.Scheduler.V1.MsgScheduleExecuteContract,
    deprecated: false
  )
end
