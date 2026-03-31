defmodule Cosmos.Group.V1.Exec do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:EXEC_UNSPECIFIED, 0)
  field(:EXEC_TRY, 1)
end

defmodule Cosmos.Group.V1.MsgCreateGroup do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:admin, 1, type: :string, deprecated: false)
  field(:members, 2, repeated: true, type: Cosmos.Group.V1.MemberRequest, deprecated: false)
  field(:metadata, 3, type: :string)
end

defmodule Cosmos.Group.V1.MsgCreateGroupResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:group_id, 1, type: :uint64, json_name: "groupId")
end

defmodule Cosmos.Group.V1.MsgUpdateGroupMembers do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:admin, 1, type: :string, deprecated: false)
  field(:group_id, 2, type: :uint64, json_name: "groupId")

  field(:member_updates, 3,
    repeated: true,
    type: Cosmos.Group.V1.MemberRequest,
    json_name: "memberUpdates",
    deprecated: false
  )
end

defmodule Cosmos.Group.V1.MsgUpdateGroupMembersResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Group.V1.MsgUpdateGroupAdmin do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:admin, 1, type: :string, deprecated: false)
  field(:group_id, 2, type: :uint64, json_name: "groupId")
  field(:new_admin, 3, type: :string, json_name: "newAdmin", deprecated: false)
end

defmodule Cosmos.Group.V1.MsgUpdateGroupAdminResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Group.V1.MsgUpdateGroupMetadata do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:admin, 1, type: :string, deprecated: false)
  field(:group_id, 2, type: :uint64, json_name: "groupId")
  field(:metadata, 3, type: :string)
end

defmodule Cosmos.Group.V1.MsgUpdateGroupMetadataResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Group.V1.MsgCreateGroupPolicy do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:admin, 1, type: :string, deprecated: false)
  field(:group_id, 2, type: :uint64, json_name: "groupId")
  field(:metadata, 3, type: :string)

  field(:decision_policy, 4,
    type: Google.Protobuf.Any,
    json_name: "decisionPolicy",
    deprecated: false
  )
end

defmodule Cosmos.Group.V1.MsgCreateGroupPolicyResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)
end

defmodule Cosmos.Group.V1.MsgUpdateGroupPolicyAdmin do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:admin, 1, type: :string, deprecated: false)

  field(:group_policy_address, 2,
    type: :string,
    json_name: "groupPolicyAddress",
    deprecated: false
  )

  field(:new_admin, 3, type: :string, json_name: "newAdmin", deprecated: false)
end

defmodule Cosmos.Group.V1.MsgUpdateGroupPolicyAdminResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Group.V1.MsgCreateGroupWithPolicy do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:admin, 1, type: :string, deprecated: false)
  field(:members, 2, repeated: true, type: Cosmos.Group.V1.MemberRequest, deprecated: false)
  field(:group_metadata, 3, type: :string, json_name: "groupMetadata")
  field(:group_policy_metadata, 4, type: :string, json_name: "groupPolicyMetadata")
  field(:group_policy_as_admin, 5, type: :bool, json_name: "groupPolicyAsAdmin")

  field(:decision_policy, 6,
    type: Google.Protobuf.Any,
    json_name: "decisionPolicy",
    deprecated: false
  )
end

defmodule Cosmos.Group.V1.MsgCreateGroupWithPolicyResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:group_id, 1, type: :uint64, json_name: "groupId")

  field(:group_policy_address, 2,
    type: :string,
    json_name: "groupPolicyAddress",
    deprecated: false
  )
end

defmodule Cosmos.Group.V1.MsgUpdateGroupPolicyDecisionPolicy do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:admin, 1, type: :string, deprecated: false)

  field(:group_policy_address, 2,
    type: :string,
    json_name: "groupPolicyAddress",
    deprecated: false
  )

  field(:decision_policy, 3,
    type: Google.Protobuf.Any,
    json_name: "decisionPolicy",
    deprecated: false
  )
end

defmodule Cosmos.Group.V1.MsgUpdateGroupPolicyDecisionPolicyResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Group.V1.MsgUpdateGroupPolicyMetadata do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:admin, 1, type: :string, deprecated: false)

  field(:group_policy_address, 2,
    type: :string,
    json_name: "groupPolicyAddress",
    deprecated: false
  )

  field(:metadata, 3, type: :string)
end

defmodule Cosmos.Group.V1.MsgUpdateGroupPolicyMetadataResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Group.V1.MsgSubmitProposal do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:group_policy_address, 1,
    type: :string,
    json_name: "groupPolicyAddress",
    deprecated: false
  )

  field(:proposers, 2, repeated: true, type: :string)
  field(:metadata, 3, type: :string)
  field(:messages, 4, repeated: true, type: Google.Protobuf.Any)
  field(:exec, 5, type: Cosmos.Group.V1.Exec, enum: true)
  field(:title, 6, type: :string)
  field(:summary, 7, type: :string)
end

defmodule Cosmos.Group.V1.MsgSubmitProposalResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId")
end

defmodule Cosmos.Group.V1.MsgWithdrawProposal do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId")
  field(:address, 2, type: :string, deprecated: false)
end

defmodule Cosmos.Group.V1.MsgWithdrawProposalResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Group.V1.MsgVote do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId")
  field(:voter, 2, type: :string, deprecated: false)
  field(:option, 3, type: Cosmos.Group.V1.VoteOption, enum: true)
  field(:metadata, 4, type: :string)
  field(:exec, 5, type: Cosmos.Group.V1.Exec, enum: true)
end

defmodule Cosmos.Group.V1.MsgVoteResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Group.V1.MsgExec do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId")
  field(:executor, 2, type: :string, deprecated: false)
end

defmodule Cosmos.Group.V1.MsgExecResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:result, 2, type: Cosmos.Group.V1.ProposalExecutorResult, enum: true)
end

defmodule Cosmos.Group.V1.MsgLeaveGroup do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)
  field(:group_id, 2, type: :uint64, json_name: "groupId")
end

defmodule Cosmos.Group.V1.MsgLeaveGroupResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Group.V1.Msg.Service do
  @moduledoc false

  use GRPC.Service, name: "cosmos.group.v1.Msg", protoc_gen_elixir_version: "0.13.0"

  rpc(:CreateGroup, Cosmos.Group.V1.MsgCreateGroup, Cosmos.Group.V1.MsgCreateGroupResponse)

  rpc(
    :UpdateGroupMembers,
    Cosmos.Group.V1.MsgUpdateGroupMembers,
    Cosmos.Group.V1.MsgUpdateGroupMembersResponse
  )

  rpc(
    :UpdateGroupAdmin,
    Cosmos.Group.V1.MsgUpdateGroupAdmin,
    Cosmos.Group.V1.MsgUpdateGroupAdminResponse
  )

  rpc(
    :UpdateGroupMetadata,
    Cosmos.Group.V1.MsgUpdateGroupMetadata,
    Cosmos.Group.V1.MsgUpdateGroupMetadataResponse
  )

  rpc(
    :CreateGroupPolicy,
    Cosmos.Group.V1.MsgCreateGroupPolicy,
    Cosmos.Group.V1.MsgCreateGroupPolicyResponse
  )

  rpc(
    :CreateGroupWithPolicy,
    Cosmos.Group.V1.MsgCreateGroupWithPolicy,
    Cosmos.Group.V1.MsgCreateGroupWithPolicyResponse
  )

  rpc(
    :UpdateGroupPolicyAdmin,
    Cosmos.Group.V1.MsgUpdateGroupPolicyAdmin,
    Cosmos.Group.V1.MsgUpdateGroupPolicyAdminResponse
  )

  rpc(
    :UpdateGroupPolicyDecisionPolicy,
    Cosmos.Group.V1.MsgUpdateGroupPolicyDecisionPolicy,
    Cosmos.Group.V1.MsgUpdateGroupPolicyDecisionPolicyResponse
  )

  rpc(
    :UpdateGroupPolicyMetadata,
    Cosmos.Group.V1.MsgUpdateGroupPolicyMetadata,
    Cosmos.Group.V1.MsgUpdateGroupPolicyMetadataResponse
  )

  rpc(
    :SubmitProposal,
    Cosmos.Group.V1.MsgSubmitProposal,
    Cosmos.Group.V1.MsgSubmitProposalResponse
  )

  rpc(
    :WithdrawProposal,
    Cosmos.Group.V1.MsgWithdrawProposal,
    Cosmos.Group.V1.MsgWithdrawProposalResponse
  )

  rpc(:Vote, Cosmos.Group.V1.MsgVote, Cosmos.Group.V1.MsgVoteResponse)

  rpc(:Exec, Cosmos.Group.V1.MsgExec, Cosmos.Group.V1.MsgExecResponse)

  rpc(:LeaveGroup, Cosmos.Group.V1.MsgLeaveGroup, Cosmos.Group.V1.MsgLeaveGroupResponse)
end

defmodule Cosmos.Group.V1.Msg.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.Group.V1.Msg.Service
end
