defmodule Tendermint.Types.SignedMsgType do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:SIGNED_MSG_TYPE_UNKNOWN, 0)
  field(:SIGNED_MSG_TYPE_PREVOTE, 1)
  field(:SIGNED_MSG_TYPE_PRECOMMIT, 2)
  field(:SIGNED_MSG_TYPE_PROPOSAL, 32)
end

defmodule Tendermint.Types.PartSetHeader do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:total, 1, type: :uint32)
  field(:hash, 2, type: :bytes)
end

defmodule Tendermint.Types.Part do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:index, 1, type: :uint32)
  field(:bytes, 2, type: :bytes)
  field(:proof, 3, type: Tendermint.Crypto.Proof, deprecated: false)
end

defmodule Tendermint.Types.BlockID do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:hash, 1, type: :bytes)

  field(:part_set_header, 2,
    type: Tendermint.Types.PartSetHeader,
    json_name: "partSetHeader",
    deprecated: false
  )
end

defmodule Tendermint.Types.Header do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:version, 1, type: Tendermint.Version.Consensus, deprecated: false)
  field(:chain_id, 2, type: :string, json_name: "chainId", deprecated: false)
  field(:height, 3, type: :int64)
  field(:time, 4, type: Google.Protobuf.Timestamp, deprecated: false)

  field(:last_block_id, 5,
    type: Tendermint.Types.BlockID,
    json_name: "lastBlockId",
    deprecated: false
  )

  field(:last_commit_hash, 6, type: :bytes, json_name: "lastCommitHash")
  field(:data_hash, 7, type: :bytes, json_name: "dataHash")
  field(:validators_hash, 8, type: :bytes, json_name: "validatorsHash")
  field(:next_validators_hash, 9, type: :bytes, json_name: "nextValidatorsHash")
  field(:consensus_hash, 10, type: :bytes, json_name: "consensusHash")
  field(:app_hash, 11, type: :bytes, json_name: "appHash")
  field(:last_results_hash, 12, type: :bytes, json_name: "lastResultsHash")
  field(:evidence_hash, 13, type: :bytes, json_name: "evidenceHash")
  field(:proposer_address, 14, type: :bytes, json_name: "proposerAddress")
end

defmodule Tendermint.Types.Data do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:txs, 1, repeated: true, type: :bytes)
end

defmodule Tendermint.Types.Vote do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:type, 1, type: Tendermint.Types.SignedMsgType, enum: true)
  field(:height, 2, type: :int64)
  field(:round, 3, type: :int32)
  field(:block_id, 4, type: Tendermint.Types.BlockID, json_name: "blockId", deprecated: false)
  field(:timestamp, 5, type: Google.Protobuf.Timestamp, deprecated: false)
  field(:validator_address, 6, type: :bytes, json_name: "validatorAddress")
  field(:validator_index, 7, type: :int32, json_name: "validatorIndex")
  field(:signature, 8, type: :bytes)
  field(:extension, 9, type: :bytes)
  field(:extension_signature, 10, type: :bytes, json_name: "extensionSignature")
end

defmodule Tendermint.Types.Commit do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :int64)
  field(:round, 2, type: :int32)
  field(:block_id, 3, type: Tendermint.Types.BlockID, json_name: "blockId", deprecated: false)
  field(:signatures, 4, repeated: true, type: Tendermint.Types.CommitSig, deprecated: false)
end

defmodule Tendermint.Types.CommitSig do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:block_id_flag, 1,
    type: Tendermint.Types.BlockIDFlag,
    json_name: "blockIdFlag",
    enum: true
  )

  field(:validator_address, 2, type: :bytes, json_name: "validatorAddress")
  field(:timestamp, 3, type: Google.Protobuf.Timestamp, deprecated: false)
  field(:signature, 4, type: :bytes)
end

defmodule Tendermint.Types.ExtendedCommit do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :int64)
  field(:round, 2, type: :int32)
  field(:block_id, 3, type: Tendermint.Types.BlockID, json_name: "blockId", deprecated: false)

  field(:extended_signatures, 4,
    repeated: true,
    type: Tendermint.Types.ExtendedCommitSig,
    json_name: "extendedSignatures",
    deprecated: false
  )
end

defmodule Tendermint.Types.ExtendedCommitSig do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:block_id_flag, 1,
    type: Tendermint.Types.BlockIDFlag,
    json_name: "blockIdFlag",
    enum: true
  )

  field(:validator_address, 2, type: :bytes, json_name: "validatorAddress")
  field(:timestamp, 3, type: Google.Protobuf.Timestamp, deprecated: false)
  field(:signature, 4, type: :bytes)
  field(:extension, 5, type: :bytes)
  field(:extension_signature, 6, type: :bytes, json_name: "extensionSignature")
end

defmodule Tendermint.Types.Proposal do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:type, 1, type: Tendermint.Types.SignedMsgType, enum: true)
  field(:height, 2, type: :int64)
  field(:round, 3, type: :int32)
  field(:pol_round, 4, type: :int32, json_name: "polRound")
  field(:block_id, 5, type: Tendermint.Types.BlockID, json_name: "blockId", deprecated: false)
  field(:timestamp, 6, type: Google.Protobuf.Timestamp, deprecated: false)
  field(:signature, 7, type: :bytes)
end

defmodule Tendermint.Types.SignedHeader do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:header, 1, type: Tendermint.Types.Header)
  field(:commit, 2, type: Tendermint.Types.Commit)
end

defmodule Tendermint.Types.LightBlock do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:signed_header, 1, type: Tendermint.Types.SignedHeader, json_name: "signedHeader")
  field(:validator_set, 2, type: Tendermint.Types.ValidatorSet, json_name: "validatorSet")
end

defmodule Tendermint.Types.BlockMeta do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:block_id, 1, type: Tendermint.Types.BlockID, json_name: "blockId", deprecated: false)
  field(:block_size, 2, type: :int64, json_name: "blockSize")
  field(:header, 3, type: Tendermint.Types.Header, deprecated: false)
  field(:num_txs, 4, type: :int64, json_name: "numTxs")
end

defmodule Tendermint.Types.TxProof do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:root_hash, 1, type: :bytes, json_name: "rootHash")
  field(:data, 2, type: :bytes)
  field(:proof, 3, type: Tendermint.Crypto.Proof)
end
