defmodule Cosmos.Base.Tendermint.V1beta1.Block do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:header, 1, type: Cosmos.Base.Tendermint.V1beta1.Header, deprecated: false)
  field(:data, 2, type: Tendermint.Types.Data, deprecated: false)
  field(:evidence, 3, type: Tendermint.Types.EvidenceList, deprecated: false)
  field(:last_commit, 4, type: Tendermint.Types.Commit, json_name: "lastCommit")
end

defmodule Cosmos.Base.Tendermint.V1beta1.Header do
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
  field(:proposer_address, 14, type: :string, json_name: "proposerAddress")
end
