defmodule Cosmos.Staking.Module.V1.Module do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:hooks_order, 1, repeated: true, type: :string, json_name: "hooksOrder")
  field(:authority, 2, type: :string)
  field(:bech32_prefix_validator, 3, type: :string, json_name: "bech32PrefixValidator")
  field(:bech32_prefix_consensus, 4, type: :string, json_name: "bech32PrefixConsensus")
end
