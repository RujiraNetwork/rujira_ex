defmodule Cosmos.Slashing.V1beta1.ValidatorSigningInfo do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)
  field(:start_height, 2, type: :int64, json_name: "startHeight")
  field(:index_offset, 3, type: :int64, json_name: "indexOffset")

  field(:jailed_until, 4,
    type: Google.Protobuf.Timestamp,
    json_name: "jailedUntil",
    deprecated: false
  )

  field(:tombstoned, 5, type: :bool)
  field(:missed_blocks_counter, 6, type: :int64, json_name: "missedBlocksCounter")
end

defmodule Cosmos.Slashing.V1beta1.Params do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:signed_blocks_window, 1, type: :int64, json_name: "signedBlocksWindow")

  field(:min_signed_per_window, 2,
    type: :bytes,
    json_name: "minSignedPerWindow",
    deprecated: false
  )

  field(:downtime_jail_duration, 3,
    type: Google.Protobuf.Duration,
    json_name: "downtimeJailDuration",
    deprecated: false
  )

  field(:slash_fraction_double_sign, 4,
    type: :bytes,
    json_name: "slashFractionDoubleSign",
    deprecated: false
  )

  field(:slash_fraction_downtime, 5,
    type: :bytes,
    json_name: "slashFractionDowntime",
    deprecated: false
  )
end
