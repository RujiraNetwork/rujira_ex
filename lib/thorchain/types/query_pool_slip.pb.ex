defmodule Thorchain.Types.QueryPoolSlipRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asset, 1, type: :string)
  field(:height, 2, type: :string)
end

defmodule Thorchain.Types.QueryPoolSlipResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asset, 1, type: :string, deprecated: false)
  field(:pool_slip, 2, type: :int64, json_name: "poolSlip", deprecated: false)
  field(:rollup_count, 3, type: :int64, json_name: "rollupCount", deprecated: false)
  field(:long_rollup, 4, type: :int64, json_name: "longRollup", deprecated: false)
  field(:rollup, 5, type: :int64, deprecated: false)
  field(:summed_rollup, 6, type: :int64, json_name: "summedRollup", deprecated: false)
end

defmodule Thorchain.Types.QueryPoolSlipsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
end

defmodule Thorchain.Types.QueryPoolSlipsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pool_slips, 1,
    repeated: true,
    type: Thorchain.Types.QueryPoolSlipResponse,
    json_name: "poolSlips"
  )
end
