defmodule Thorchain.Types.SolvencyVoter do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:id, 1, type: :string, deprecated: false)
  field(:chain, 2, type: :string, deprecated: false)
  field(:pub_key, 3, type: :string, json_name: "pubKey", deprecated: false)
  field(:coins, 4, repeated: true, type: Thorchain.Common.Coin, deprecated: false)
  field(:height, 5, type: :int64)
  field(:consensus_block_height, 6, type: :int64, json_name: "consensusBlockHeight")
  field(:signers, 7, repeated: true, type: :string)
end
