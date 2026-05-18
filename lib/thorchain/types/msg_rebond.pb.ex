defmodule Thorchain.Types.MsgReBond do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx_in, 1, type: Thorchain.Common.Tx, json_name: "txIn", deprecated: false)
  field(:node_address, 2, type: :bytes, json_name: "nodeAddress", deprecated: false)

  field(:new_bond_provider_address, 3,
    type: :bytes,
    json_name: "newBondProviderAddress",
    deprecated: false
  )

  field(:amount, 4, type: :string, deprecated: false)
  field(:signer, 5, type: :bytes, deprecated: false)
end
