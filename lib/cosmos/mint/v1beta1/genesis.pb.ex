defmodule Cosmos.Mint.V1beta1.GenesisState do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:minter, 1, type: Cosmos.Mint.V1beta1.Minter, deprecated: false)
  field(:params, 2, type: Cosmos.Mint.V1beta1.Params, deprecated: false)
end
