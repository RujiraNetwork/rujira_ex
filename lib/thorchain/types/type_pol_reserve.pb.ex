defmodule Thorchain.Types.POLReserveDeposit do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asset, 1, type: Thorchain.Common.Asset, deprecated: false)
  field(:rune_deposited, 2, type: :string, json_name: "runeDeposited", deprecated: false)
end
