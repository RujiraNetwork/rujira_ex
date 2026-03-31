defmodule Thorchain.Types.Network do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:bond_reward_rune, 1, type: :string, json_name: "bondRewardRune", deprecated: false)
  field(:total_bond_units, 2, type: :string, json_name: "totalBondUnits", deprecated: false)
  field(:LPIncomeSplit, 5, type: :int64)
  field(:NodeIncomeSplit, 6, type: :int64)
  field(:outbound_gas_spent_rune, 7, type: :uint64, json_name: "outboundGasSpentRune")
  field(:outbound_gas_withheld_rune, 8, type: :uint64, json_name: "outboundGasWithheldRune")
end
