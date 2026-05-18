defmodule Thorchain.Types.ReferenceMemo do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asset, 1, type: Thorchain.Common.Asset, deprecated: false)
  field(:memo, 2, type: :string)
  field(:reference, 3, type: :string)
  field(:height, 4, type: :int64)
  field(:registration_hash, 5, type: :string, json_name: "registrationHash", deprecated: false)
  field(:registered_by, 6, type: :bytes, json_name: "registeredBy", deprecated: false)
  field(:used_by_txs, 7, repeated: true, type: :string, json_name: "usedByTxs", deprecated: false)
end
