defmodule Cosmos.Group.V1.QueryGroupInfoRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:group_id, 1, type: :uint64, json_name: "groupId")
end

defmodule Cosmos.Group.V1.QueryGroupInfoResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:info, 1, type: Cosmos.Group.V1.GroupInfo)
end

defmodule Cosmos.Group.V1.QueryGroupPolicyInfoRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)
end

defmodule Cosmos.Group.V1.QueryGroupPolicyInfoResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:info, 1, type: Cosmos.Group.V1.GroupPolicyInfo)
end

defmodule Cosmos.Group.V1.QueryGroupMembersRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:group_id, 1, type: :uint64, json_name: "groupId")
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Group.V1.QueryGroupMembersResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:members, 1, repeated: true, type: Cosmos.Group.V1.GroupMember)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Group.V1.QueryGroupsByAdminRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:admin, 1, type: :string, deprecated: false)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Group.V1.QueryGroupsByAdminResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:groups, 1, repeated: true, type: Cosmos.Group.V1.GroupInfo)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Group.V1.QueryGroupPoliciesByGroupRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:group_id, 1, type: :uint64, json_name: "groupId")
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Group.V1.QueryGroupPoliciesByGroupResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:group_policies, 1,
    repeated: true,
    type: Cosmos.Group.V1.GroupPolicyInfo,
    json_name: "groupPolicies"
  )

  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Group.V1.QueryGroupPoliciesByAdminRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:admin, 1, type: :string, deprecated: false)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Group.V1.QueryGroupPoliciesByAdminResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:group_policies, 1,
    repeated: true,
    type: Cosmos.Group.V1.GroupPolicyInfo,
    json_name: "groupPolicies"
  )

  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Group.V1.QueryProposalRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId")
end

defmodule Cosmos.Group.V1.QueryProposalResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal, 1, type: Cosmos.Group.V1.Proposal)
end

defmodule Cosmos.Group.V1.QueryProposalsByGroupPolicyRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Group.V1.QueryProposalsByGroupPolicyResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposals, 1, repeated: true, type: Cosmos.Group.V1.Proposal)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Group.V1.QueryVoteByProposalVoterRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId")
  field(:voter, 2, type: :string, deprecated: false)
end

defmodule Cosmos.Group.V1.QueryVoteByProposalVoterResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:vote, 1, type: Cosmos.Group.V1.Vote)
end

defmodule Cosmos.Group.V1.QueryVotesByProposalRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId")
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Group.V1.QueryVotesByProposalResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:votes, 1, repeated: true, type: Cosmos.Group.V1.Vote)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Group.V1.QueryVotesByVoterRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:voter, 1, type: :string, deprecated: false)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Group.V1.QueryVotesByVoterResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:votes, 1, repeated: true, type: Cosmos.Group.V1.Vote)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Group.V1.QueryGroupsByMemberRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Group.V1.QueryGroupsByMemberResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:groups, 1, repeated: true, type: Cosmos.Group.V1.GroupInfo)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Group.V1.QueryTallyResultRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId")
end

defmodule Cosmos.Group.V1.QueryTallyResultResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tally, 1, type: Cosmos.Group.V1.TallyResult, deprecated: false)
end

defmodule Cosmos.Group.V1.QueryGroupsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Group.V1.QueryGroupsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:groups, 1, repeated: true, type: Cosmos.Group.V1.GroupInfo)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Group.V1.Query.Service do
  @moduledoc false

  use GRPC.Service, name: "cosmos.group.v1.Query", protoc_gen_elixir_version: "0.13.0"

  rpc(:GroupInfo, Cosmos.Group.V1.QueryGroupInfoRequest, Cosmos.Group.V1.QueryGroupInfoResponse)

  rpc(
    :GroupPolicyInfo,
    Cosmos.Group.V1.QueryGroupPolicyInfoRequest,
    Cosmos.Group.V1.QueryGroupPolicyInfoResponse
  )

  rpc(
    :GroupMembers,
    Cosmos.Group.V1.QueryGroupMembersRequest,
    Cosmos.Group.V1.QueryGroupMembersResponse
  )

  rpc(
    :GroupsByAdmin,
    Cosmos.Group.V1.QueryGroupsByAdminRequest,
    Cosmos.Group.V1.QueryGroupsByAdminResponse
  )

  rpc(
    :GroupPoliciesByGroup,
    Cosmos.Group.V1.QueryGroupPoliciesByGroupRequest,
    Cosmos.Group.V1.QueryGroupPoliciesByGroupResponse
  )

  rpc(
    :GroupPoliciesByAdmin,
    Cosmos.Group.V1.QueryGroupPoliciesByAdminRequest,
    Cosmos.Group.V1.QueryGroupPoliciesByAdminResponse
  )

  rpc(:Proposal, Cosmos.Group.V1.QueryProposalRequest, Cosmos.Group.V1.QueryProposalResponse)

  rpc(
    :ProposalsByGroupPolicy,
    Cosmos.Group.V1.QueryProposalsByGroupPolicyRequest,
    Cosmos.Group.V1.QueryProposalsByGroupPolicyResponse
  )

  rpc(
    :VoteByProposalVoter,
    Cosmos.Group.V1.QueryVoteByProposalVoterRequest,
    Cosmos.Group.V1.QueryVoteByProposalVoterResponse
  )

  rpc(
    :VotesByProposal,
    Cosmos.Group.V1.QueryVotesByProposalRequest,
    Cosmos.Group.V1.QueryVotesByProposalResponse
  )

  rpc(
    :VotesByVoter,
    Cosmos.Group.V1.QueryVotesByVoterRequest,
    Cosmos.Group.V1.QueryVotesByVoterResponse
  )

  rpc(
    :GroupsByMember,
    Cosmos.Group.V1.QueryGroupsByMemberRequest,
    Cosmos.Group.V1.QueryGroupsByMemberResponse
  )

  rpc(
    :TallyResult,
    Cosmos.Group.V1.QueryTallyResultRequest,
    Cosmos.Group.V1.QueryTallyResultResponse
  )

  rpc(:Groups, Cosmos.Group.V1.QueryGroupsRequest, Cosmos.Group.V1.QueryGroupsResponse)
end

defmodule Cosmos.Group.V1.Query.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.Group.V1.Query.Service
end
