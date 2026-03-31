defmodule Thorchain.Types.RUNEPool do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:reserve_units, 1, type: :string, json_name: "reserveUnits", deprecated: false)
  field(:pool_units, 2, type: :string, json_name: "poolUnits", deprecated: false)
  field(:rune_deposited, 3, type: :string, json_name: "runeDeposited", deprecated: false)
  field(:rune_withdrawn, 4, type: :string, json_name: "runeWithdrawn", deprecated: false)
end
