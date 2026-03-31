defmodule Cosmos.Group.V1.GenesisState do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:group_seq, 1, type: :uint64, json_name: "groupSeq")
  field(:groups, 2, repeated: true, type: Cosmos.Group.V1.GroupInfo)

  field(:group_members, 3,
    repeated: true,
    type: Cosmos.Group.V1.GroupMember,
    json_name: "groupMembers"
  )

  field(:group_policy_seq, 4, type: :uint64, json_name: "groupPolicySeq")

  field(:group_policies, 5,
    repeated: true,
    type: Cosmos.Group.V1.GroupPolicyInfo,
    json_name: "groupPolicies"
  )

  field(:proposal_seq, 6, type: :uint64, json_name: "proposalSeq")
  field(:proposals, 7, repeated: true, type: Cosmos.Group.V1.Proposal)
  field(:votes, 8, repeated: true, type: Cosmos.Group.V1.Vote)
end
