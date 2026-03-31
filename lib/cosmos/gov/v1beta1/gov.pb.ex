defmodule Cosmos.Gov.V1beta1.VoteOption do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:VOTE_OPTION_UNSPECIFIED, 0)
  field(:VOTE_OPTION_YES, 1)
  field(:VOTE_OPTION_ABSTAIN, 2)
  field(:VOTE_OPTION_NO, 3)
  field(:VOTE_OPTION_NO_WITH_VETO, 4)
end

defmodule Cosmos.Gov.V1beta1.ProposalStatus do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:PROPOSAL_STATUS_UNSPECIFIED, 0)
  field(:PROPOSAL_STATUS_DEPOSIT_PERIOD, 1)
  field(:PROPOSAL_STATUS_VOTING_PERIOD, 2)
  field(:PROPOSAL_STATUS_PASSED, 3)
  field(:PROPOSAL_STATUS_REJECTED, 4)
  field(:PROPOSAL_STATUS_FAILED, 5)
end

defmodule Cosmos.Gov.V1beta1.WeightedVoteOption do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:option, 1, type: Cosmos.Gov.V1beta1.VoteOption, enum: true)
  field(:weight, 2, type: :string, deprecated: false)
end

defmodule Cosmos.Gov.V1beta1.TextProposal do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:title, 1, type: :string)
  field(:description, 2, type: :string)
end

defmodule Cosmos.Gov.V1beta1.Deposit do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId")
  field(:depositor, 2, type: :string, deprecated: false)
  field(:amount, 3, repeated: true, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
end

defmodule Cosmos.Gov.V1beta1.Proposal do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId")
  field(:content, 2, type: Google.Protobuf.Any, deprecated: false)
  field(:status, 3, type: Cosmos.Gov.V1beta1.ProposalStatus, enum: true)

  field(:final_tally_result, 4,
    type: Cosmos.Gov.V1beta1.TallyResult,
    json_name: "finalTallyResult",
    deprecated: false
  )

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
end

defmodule Cosmos.Gov.V1beta1.TallyResult do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:yes, 1, type: :string, deprecated: false)
  field(:abstain, 2, type: :string, deprecated: false)
  field(:no, 3, type: :string, deprecated: false)
  field(:no_with_veto, 4, type: :string, json_name: "noWithVeto", deprecated: false)
end

defmodule Cosmos.Gov.V1beta1.Vote do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId", deprecated: false)
  field(:voter, 2, type: :string, deprecated: false)
  field(:option, 3, type: Cosmos.Gov.V1beta1.VoteOption, enum: true, deprecated: true)

  field(:options, 4,
    repeated: true,
    type: Cosmos.Gov.V1beta1.WeightedVoteOption,
    deprecated: false
  )
end

defmodule Cosmos.Gov.V1beta1.DepositParams do
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
end

defmodule Cosmos.Gov.V1beta1.VotingParams do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:voting_period, 1,
    type: Google.Protobuf.Duration,
    json_name: "votingPeriod",
    deprecated: false
  )
end

defmodule Cosmos.Gov.V1beta1.TallyParams do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:quorum, 1, type: :bytes, deprecated: false)
  field(:threshold, 2, type: :bytes, deprecated: false)
  field(:veto_threshold, 3, type: :bytes, json_name: "vetoThreshold", deprecated: false)
end
