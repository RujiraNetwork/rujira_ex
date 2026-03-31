defmodule Cosmos.Gov.V1.VoteOption do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:VOTE_OPTION_UNSPECIFIED, 0)
  field(:VOTE_OPTION_YES, 1)
  field(:VOTE_OPTION_ABSTAIN, 2)
  field(:VOTE_OPTION_NO, 3)
  field(:VOTE_OPTION_NO_WITH_VETO, 4)
end

defmodule Cosmos.Gov.V1.ProposalStatus do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:PROPOSAL_STATUS_UNSPECIFIED, 0)
  field(:PROPOSAL_STATUS_DEPOSIT_PERIOD, 1)
  field(:PROPOSAL_STATUS_VOTING_PERIOD, 2)
  field(:PROPOSAL_STATUS_PASSED, 3)
  field(:PROPOSAL_STATUS_REJECTED, 4)
  field(:PROPOSAL_STATUS_FAILED, 5)
end

defmodule Cosmos.Gov.V1.WeightedVoteOption do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:option, 1, type: Cosmos.Gov.V1.VoteOption, enum: true)
  field(:weight, 2, type: :string, deprecated: false)
end

defmodule Cosmos.Gov.V1.Deposit do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId")
  field(:depositor, 2, type: :string, deprecated: false)
  field(:amount, 3, repeated: true, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
end

defmodule Cosmos.Gov.V1.Proposal do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:id, 1, type: :uint64)
  field(:messages, 2, repeated: true, type: Google.Protobuf.Any)
  field(:status, 3, type: Cosmos.Gov.V1.ProposalStatus, enum: true)
  field(:final_tally_result, 4, type: Cosmos.Gov.V1.TallyResult, json_name: "finalTallyResult")

  field(:submit_time, 5,
    type: Google.Protobuf.Timestamp,
    json_name: "submitTime",
    deprecated: false
  )

  field(:deposit_end_time, 6,
    type: Google.Protobuf.Timestamp,
    json_name: "depositEndTime",
    deprecated: false
  )

  field(:total_deposit, 7,
    repeated: true,
    type: Cosmos.Base.V1beta1.Coin,
    json_name: "totalDeposit",
    deprecated: false
  )

  field(:voting_start_time, 8,
    type: Google.Protobuf.Timestamp,
    json_name: "votingStartTime",
    deprecated: false
  )

  field(:voting_end_time, 9,
    type: Google.Protobuf.Timestamp,
    json_name: "votingEndTime",
    deprecated: false
  )

  field(:metadata, 10, type: :string)
  field(:title, 11, type: :string)
  field(:summary, 12, type: :string)
  field(:proposer, 13, type: :string, deprecated: false)
  field(:expedited, 14, type: :bool)
  field(:failed_reason, 15, type: :string, json_name: "failedReason")
end

defmodule Cosmos.Gov.V1.TallyResult do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:yes_count, 1, type: :string, json_name: "yesCount", deprecated: false)
  field(:abstain_count, 2, type: :string, json_name: "abstainCount", deprecated: false)
  field(:no_count, 3, type: :string, json_name: "noCount", deprecated: false)
  field(:no_with_veto_count, 4, type: :string, json_name: "noWithVetoCount", deprecated: false)
end

defmodule Cosmos.Gov.V1.Vote do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId")
  field(:voter, 2, type: :string, deprecated: false)
  field(:options, 4, repeated: true, type: Cosmos.Gov.V1.WeightedVoteOption)
  field(:metadata, 5, type: :string)
end

defmodule Cosmos.Gov.V1.DepositParams do
  @moduledoc false

  use Protobuf, deprecated: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:min_deposit, 1,
    repeated: true,
    type: Cosmos.Base.V1beta1.Coin,
    json_name: "minDeposit",
    deprecated: false
  )

  field(:max_deposit_period, 2,
    type: Google.Protobuf.Duration,
    json_name: "maxDepositPeriod",
    deprecated: false
  )
end

defmodule Cosmos.Gov.V1.VotingParams do
  @moduledoc false

  use Protobuf, deprecated: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:voting_period, 1,
    type: Google.Protobuf.Duration,
    json_name: "votingPeriod",
    deprecated: false
  )
end

defmodule Cosmos.Gov.V1.TallyParams do
  @moduledoc false

  use Protobuf, deprecated: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:quorum, 1, type: :string, deprecated: false)
  field(:threshold, 2, type: :string, deprecated: false)
  field(:veto_threshold, 3, type: :string, json_name: "vetoThreshold", deprecated: false)
end

defmodule Cosmos.Gov.V1.Params do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:min_deposit, 1,
    repeated: true,
    type: Cosmos.Base.V1beta1.Coin,
    json_name: "minDeposit",
    deprecated: false
  )

  field(:max_deposit_period, 2,
    type: Google.Protobuf.Duration,
    json_name: "maxDepositPeriod",
    deprecated: false
  )

  field(:voting_period, 3,
    type: Google.Protobuf.Duration,
    json_name: "votingPeriod",
    deprecated: false
  )

  field(:quorum, 4, type: :string, deprecated: false)
  field(:threshold, 5, type: :string, deprecated: false)
  field(:veto_threshold, 6, type: :string, json_name: "vetoThreshold", deprecated: false)

  field(:min_initial_deposit_ratio, 7,
    type: :string,
    json_name: "minInitialDepositRatio",
    deprecated: false
  )

  field(:proposal_cancel_ratio, 8,
    type: :string,
    json_name: "proposalCancelRatio",
    deprecated: false
  )

  field(:proposal_cancel_dest, 9,
    type: :string,
    json_name: "proposalCancelDest",
    deprecated: false
  )

  field(:expedited_voting_period, 10,
    type: Google.Protobuf.Duration,
    json_name: "expeditedVotingPeriod",
    deprecated: false
  )

  field(:expedited_threshold, 11,
    type: :string,
    json_name: "expeditedThreshold",
    deprecated: false
  )

  field(:expedited_min_deposit, 12,
    repeated: true,
    type: Cosmos.Base.V1beta1.Coin,
    json_name: "expeditedMinDeposit",
    deprecated: false
  )

  field(:burn_vote_quorum, 13, type: :bool, json_name: "burnVoteQuorum")
  field(:burn_proposal_deposit_prevote, 14, type: :bool, json_name: "burnProposalDepositPrevote")
  field(:burn_vote_veto, 15, type: :bool, json_name: "burnVoteVeto")
  field(:min_deposit_ratio, 16, type: :string, json_name: "minDepositRatio", deprecated: false)
end
