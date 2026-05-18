defmodule Thorchain.Types.ModifyLimitSwap do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:from, 1, type: :string, deprecated: false)
  field(:source, 2, type: Thorchain.Common.Coin, deprecated: false)
  field(:target, 3, type: Thorchain.Common.Coin, deprecated: false)

  field(:modified_target_amount, 4,
    type: :string,
    json_name: "modifiedTargetAmount",
    deprecated: false
  )
end
