defmodule Thorchain.Types.ProtocolOwnedLiquidity do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:rune_deposited, 1, type: :string, json_name: "runeDeposited", deprecated: false)
  field(:rune_withdrawn, 2, type: :string, json_name: "runeWithdrawn", deprecated: false)
end
