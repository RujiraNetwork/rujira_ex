defmodule Cosmos.Group.V1.VoteOption do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:VOTE_OPTION_UNSPECIFIED, 0)
  field(:VOTE_OPTION_YES, 1)
  field(:VOTE_OPTION_ABSTAIN, 2)
  field(:VOTE_OPTION_NO, 3)
  field(:VOTE_OPTION_NO_WITH_VETO, 4)
end

defmodule Cosmos.Group.V1.ProposalStatus do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:PROPOSAL_STATUS_UNSPECIFIED, 0)
  field(:PROPOSAL_STATUS_SUBMITTED, 1)
  field(:PROPOSAL_STATUS_ACCEPTED, 2)
  field(:PROPOSAL_STATUS_REJECTED, 3)
  field(:PROPOSAL_STATUS_ABORTED, 4)
  field(:PROPOSAL_STATUS_WITHDRAWN, 5)
end

defmodule Cosmos.Group.V1.ProposalExecutorResult do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:PROPOSAL_EXECUTOR_RESULT_UNSPECIFIED, 0)
  field(:PROPOSAL_EXECUTOR_RESULT_NOT_RUN, 1)
  field(:PROPOSAL_EXECUTOR_RESULT_SUCCESS, 2)
  field(:PROPOSAL_EXECUTOR_RESULT_FAILURE, 3)
end

defmodule Cosmos.Group.V1.Member do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)
  field(:weight, 2, type: :string)
  field(:metadata, 3, type: :string)
  field(:added_at, 4, type: Google.Protobuf.Timestamp, json_name: "addedAt", deprecated: false)
end

defmodule Cosmos.Group.V1.MemberRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)
  field(:weight, 2, type: :string)
  field(:metadata, 3, type: :string)
end

defmodule Cosmos.Group.V1.ThresholdDecisionPolicy do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:threshold, 1, type: :string)
  field(:windows, 2, type: Cosmos.Group.V1.DecisionPolicyWindows)
end

defmodule Cosmos.Group.V1.PercentageDecisionPolicy do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:percentage, 1, type: :string)
  field(:windows, 2, type: Cosmos.Group.V1.DecisionPolicyWindows)
end

defmodule Cosmos.Group.V1.DecisionPolicyWindows do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:voting_period, 1,
    type: Google.Protobuf.Duration,
    json_name: "votingPeriod",
    deprecated: false
  )

  field(:min_execution_period, 2,
    type: Google.Protobuf.Duration,
    json_name: "minExecutionPeriod",
    deprecated: false
  )
end

defmodule Cosmos.Group.V1.GroupInfo do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:id, 1, type: :uint64)
  field(:admin, 2, type: :string, deprecated: false)
  field(:metadata, 3, type: :string)
  field(:version, 4, type: :uint64)
  field(:total_weight, 5, type: :string, json_name: "totalWeight")

  field(:created_at, 6,
    type: Google.Protobuf.Timestamp,
    json_name: "createdAt",
    deprecated: false
  )
end

defmodule Cosmos.Group.V1.GroupMember do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:group_id, 1, type: :uint64, json_name: "groupId")
  field(:member, 2, type: Cosmos.Group.V1.Member)
end

defmodule Cosmos.Group.V1.GroupPolicyInfo do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)
  field(:group_id, 2, type: :uint64, json_name: "groupId")
  field(:admin, 3, type: :string, deprecated: false)
  field(:metadata, 4, type: :string)
  field(:version, 5, type: :uint64)

  field(:decision_policy, 6,
    type: Google.Protobuf.Any,
    json_name: "decisionPolicy",
    deprecated: false
  )

  field(:created_at, 7,
    type: Google.Protobuf.Timestamp,
    json_name: "createdAt",
    deprecated: false
  )
end

defmodule Cosmos.Group.V1.Proposal do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:id, 1, type: :uint64)

  field(:group_policy_address, 2,
    type: :string,
    json_name: "groupPolicyAddress",
    deprecated: false
  )

  field(:metadata, 3, type: :string)
  field(:proposers, 4, repeated: true, type: :string, deprecated: false)

  field(:submit_time, 5,
    type: Google.Protobuf.Timestamp,
    json_name: "submitTime",
    deprecated: false
  )

  field(:group_version, 6, type: :uint64, json_name: "groupVersion")
  field(:group_policy_version, 7, type: :uint64, json_name: "groupPolicyVersion")
  field(:status, 8, type: Cosmos.Group.V1.ProposalStatus, enum: true)

  field(:final_tally_result, 9,
    type: Cosmos.Group.V1.TallyResult,
    json_name: "finalTallyResult",
    deprecated: false
  )

  field(:voting_period_end, 10,
    type: Google.Protobuf.Timestamp,
    json_name: "votingPeriodEnd",
    deprecated: false
  )

  field(:executor_result, 11,
    type: Cosmos.Group.V1.ProposalExecutorResult,
    json_name: "executorResult",
    enum: true
  )

  field(:messages, 12, repeated: true, type: Google.Protobuf.Any)
  field(:title, 13, type: :string)
  field(:summary, 14, type: :string)
end

defmodule Cosmos.Group.V1.TallyResult do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:yes_count, 1, type: :string, json_name: "yesCount")
  field(:abstain_count, 2, type: :string, json_name: "abstainCount")
  field(:no_count, 3, type: :string, json_name: "noCount")
  field(:no_with_veto_count, 4, type: :string, json_name: "noWithVetoCount")
end

defmodule Cosmos.Group.V1.Vote do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId")
  field(:voter, 2, type: :string, deprecated: false)
  field(:option, 3, type: Cosmos.Group.V1.VoteOption, enum: true)
  field(:metadata, 4, type: :string)

  field(:submit_time, 5,
    type: Google.Protobuf.Timestamp,
    json_name: "submitTime",
    deprecated: false
  )
end
