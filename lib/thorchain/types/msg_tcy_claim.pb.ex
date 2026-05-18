defmodule Thorchain.Types.MsgTCYClaim do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:rune_address, 1, type: :string, json_name: "runeAddress", deprecated: false)
  field(:l1_address, 2, type: :string, json_name: "l1Address", deprecated: false)
  field(:signer, 3, type: :bytes, deprecated: false)
end
