defmodule Thorchain.Types.ErrataTxVoter do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx_id, 1, type: :string, json_name: "txId", deprecated: false)
  field(:chain, 2, type: :string, deprecated: false)
  field(:block_height, 3, type: :int64, json_name: "blockHeight")
  field(:signers, 4, repeated: true, type: :string)
end
