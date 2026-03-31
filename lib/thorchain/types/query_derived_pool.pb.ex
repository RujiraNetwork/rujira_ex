defmodule Thorchain.Types.QueryDerivedPoolRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asset, 1, type: :string)
  field(:height, 2, type: :string)
end

defmodule Thorchain.Types.QueryDerivedPoolResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asset, 1, type: :string, deprecated: false)
  field(:status, 2, type: :string, deprecated: false)
  field(:decimals, 3, type: :int64)
  field(:balance_asset, 4, type: :string, json_name: "balanceAsset", deprecated: false)
  field(:balance_rune, 5, type: :string, json_name: "balanceRune", deprecated: false)
  field(:derived_depth_bps, 6, type: :string, json_name: "derivedDepthBps", deprecated: false)
end

defmodule Thorchain.Types.QueryDerivedPoolsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
end

defmodule Thorchain.Types.QueryDerivedPoolsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pools, 1, repeated: true, type: Thorchain.Types.QueryDerivedPoolResponse)
end
