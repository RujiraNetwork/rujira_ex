defmodule Cosmos.Gov.V1beta1.GenesisState do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:starting_proposal_id, 1, type: :uint64, json_name: "startingProposalId")
  field(:deposits, 2, repeated: true, type: Cosmos.Gov.V1beta1.Deposit, deprecated: false)
  field(:votes, 3, repeated: true, type: Cosmos.Gov.V1beta1.Vote, deprecated: false)
  field(:proposals, 4, repeated: true, type: Cosmos.Gov.V1beta1.Proposal, deprecated: false)

  field(:deposit_params, 5,
    type: Cosmos.Gov.V1beta1.DepositParams,
    json_name: "depositParams",
    deprecated: false
  )

  field(:voting_params, 6,
    type: Cosmos.Gov.V1beta1.VotingParams,
    json_name: "votingParams",
    deprecated: false
  )

  field(:tally_params, 7,
    type: Cosmos.Gov.V1beta1.TallyParams,
    json_name: "tallyParams",
    deprecated: false
  )
end
