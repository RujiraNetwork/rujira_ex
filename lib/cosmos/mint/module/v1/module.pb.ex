defmodule Cosmos.Mint.Module.V1.Module do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:fee_collector_name, 1, type: :string, json_name: "feeCollectorName")
  field(:authority, 2, type: :string)
end
