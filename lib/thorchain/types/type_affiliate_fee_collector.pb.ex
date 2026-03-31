defmodule Thorchain.Types.AffiliateFeeCollector do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:owner_address, 1, type: :bytes, json_name: "ownerAddress", deprecated: false)
  field(:rune_amount, 2, type: :string, json_name: "runeAmount", deprecated: false)
end
