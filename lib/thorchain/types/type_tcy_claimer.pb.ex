defmodule Thorchain.Types.TCYClaimer do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asset, 1, type: Thorchain.Common.Asset, deprecated: false)
  field(:l1_address, 2, type: :string, json_name: "l1Address", deprecated: false)
  field(:amount, 3, type: :string, deprecated: false)
end
