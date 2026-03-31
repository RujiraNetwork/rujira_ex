defmodule Thorchain.Types.TssVoter do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:id, 1, type: :string, deprecated: false)
  field(:pool_pub_key, 2, type: :string, json_name: "poolPubKey", deprecated: false)
  field(:pub_keys, 3, repeated: true, type: :string, json_name: "pubKeys")
  field(:block_height, 4, type: :int64, json_name: "blockHeight")
  field(:chains, 5, repeated: true, type: :string)
  field(:signers, 6, repeated: true, type: :string)

  field(:majority_consensus_block_height, 7,
    type: :int64,
    json_name: "majorityConsensusBlockHeight"
  )

  field(:secp256k1_signatures, 8, repeated: true, type: :string, json_name: "secp256k1Signatures")
end
