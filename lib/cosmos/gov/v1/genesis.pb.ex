defmodule Cosmos.Gov.V1.GenesisState do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:starting_proposal_id, 1, type: :uint64, json_name: "startingProposalId")
  field(:deposits, 2, repeated: true, type: Cosmos.Gov.V1.Deposit)
  field(:votes, 3, repeated: true, type: Cosmos.Gov.V1.Vote)
  field(:proposals, 4, repeated: true, type: Cosmos.Gov.V1.Proposal)

  field(:deposit_params, 5,
    type: Cosmos.Gov.V1.DepositParams,
    json_name: "depositParams",
    deprecated: true
  )

  field(:voting_params, 6,
    type: Cosmos.Gov.V1.VotingParams,
    json_name: "votingParams",
    deprecated: true
  )

  field(:tally_params, 7,
    type: Cosmos.Gov.V1.TallyParams,
    json_name: "tallyParams",
    deprecated: true
  )

  field(:params, 8, type: Cosmos.Gov.V1.Params)
  field(:constitution, 9, type: :string)
end
