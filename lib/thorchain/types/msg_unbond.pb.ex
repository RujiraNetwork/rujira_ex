defmodule Thorchain.Types.MsgUnBond do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx_in, 1, type: Thorchain.Common.Tx, json_name: "txIn", deprecated: false)
  field(:node_address, 2, type: :bytes, json_name: "nodeAddress", deprecated: false)
  field(:bond_address, 5, type: :string, json_name: "bondAddress", deprecated: false)
  field(:amount, 6, type: :string, deprecated: false)
  field(:signer, 7, type: :bytes, deprecated: false)

  field(:bond_provider_address, 8,
    type: :bytes,
    json_name: "bondProviderAddress",
    deprecated: false
  )
end
