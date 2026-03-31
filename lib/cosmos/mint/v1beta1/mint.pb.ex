defmodule Cosmos.Mint.V1beta1.Minter do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:inflation, 1, type: :string, deprecated: false)
  field(:annual_provisions, 2, type: :string, json_name: "annualProvisions", deprecated: false)
end

defmodule Cosmos.Mint.V1beta1.Params do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:mint_denom, 1, type: :string, json_name: "mintDenom")

  field(:inflation_rate_change, 2,
    type: :string,
    json_name: "inflationRateChange",
    deprecated: false
  )

  field(:inflation_max, 3, type: :string, json_name: "inflationMax", deprecated: false)
  field(:inflation_min, 4, type: :string, json_name: "inflationMin", deprecated: false)
  field(:goal_bonded, 5, type: :string, json_name: "goalBonded", deprecated: false)
  field(:blocks_per_year, 6, type: :uint64, json_name: "blocksPerYear")
end
