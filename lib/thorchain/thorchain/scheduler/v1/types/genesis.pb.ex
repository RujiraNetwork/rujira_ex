defmodule Thorchain.Thorchain.Scheduler.V1.GenesisState do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:schedules, 1,
    repeated: true,
    type: Thorchain.Thorchain.Scheduler.V1.Schedule,
    deprecated: false
  )
end
