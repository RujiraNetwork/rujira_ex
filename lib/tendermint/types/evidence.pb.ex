defmodule Tendermint.Types.Evidence do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  oneof(:sum, 0)

  field(:duplicate_vote_evidence, 1,
    type: Tendermint.Types.DuplicateVoteEvidence,
    json_name: "duplicateVoteEvidence",
    oneof: 0
  )

  field(:light_client_attack_evidence, 2,
    type: Tendermint.Types.LightClientAttackEvidence,
    json_name: "lightClientAttackEvidence",
    oneof: 0
  )
end

defmodule Tendermint.Types.DuplicateVoteEvidence do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:vote_a, 1, type: Tendermint.Types.Vote, json_name: "voteA")
  field(:vote_b, 2, type: Tendermint.Types.Vote, json_name: "voteB")
  field(:total_voting_power, 3, type: :int64, json_name: "totalVotingPower")
  field(:validator_power, 4, type: :int64, json_name: "validatorPower")
  field(:timestamp, 5, type: Google.Protobuf.Timestamp, deprecated: false)
end

defmodule Tendermint.Types.LightClientAttackEvidence do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:conflicting_block, 1, type: Tendermint.Types.LightBlock, json_name: "conflictingBlock")
  field(:common_height, 2, type: :int64, json_name: "commonHeight")

  field(:byzantine_validators, 3,
    repeated: true,
    type: Tendermint.Types.Validator,
    json_name: "byzantineValidators"
  )

  field(:total_voting_power, 4, type: :int64, json_name: "totalVotingPower")
  field(:timestamp, 5, type: Google.Protobuf.Timestamp, deprecated: false)
end

defmodule Tendermint.Types.EvidenceList do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:evidence, 1, repeated: true, type: Tendermint.Types.Evidence, deprecated: false)
end
