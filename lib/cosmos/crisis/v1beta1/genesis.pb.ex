defmodule Cosmos.Crisis.V1beta1.GenesisState do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:constant_fee, 3,
    type: Cosmos.Base.V1beta1.Coin,
    json_name: "constantFee",
    deprecated: false
  )
end
