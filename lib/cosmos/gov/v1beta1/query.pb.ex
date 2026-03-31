defmodule Cosmos.Gov.V1beta1.QueryProposalRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId")
end

defmodule Cosmos.Gov.V1beta1.QueryProposalResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal, 1, type: Cosmos.Gov.V1beta1.Proposal, deprecated: false)
end

defmodule Cosmos.Gov.V1beta1.QueryProposalsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_status, 1,
    type: Cosmos.Gov.V1beta1.ProposalStatus,
    json_name: "proposalStatus",
    enum: true
  )

  field(:voter, 2, type: :string, deprecated: false)
  field(:depositor, 3, type: :string, deprecated: false)
  field(:pagination, 4, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Gov.V1beta1.QueryProposalsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposals, 1, repeated: true, type: Cosmos.Gov.V1beta1.Proposal, deprecated: false)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Gov.V1beta1.QueryVoteRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId")
  field(:voter, 2, type: :string, deprecated: false)
end

defmodule Cosmos.Gov.V1beta1.QueryVoteResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:vote, 1, type: Cosmos.Gov.V1beta1.Vote, deprecated: false)
end

defmodule Cosmos.Gov.V1beta1.QueryVotesRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId")
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Gov.V1beta1.QueryVotesResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:votes, 1, repeated: true, type: Cosmos.Gov.V1beta1.Vote, deprecated: false)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Gov.V1beta1.QueryParamsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:params_type, 1, type: :string, json_name: "paramsType")
end

defmodule Cosmos.Gov.V1beta1.QueryParamsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:voting_params, 1,
    type: Cosmos.Gov.V1beta1.VotingParams,
    json_name: "votingParams",
    deprecated: false
  )

  field(:deposit_params, 2,
    type: Cosmos.Gov.V1beta1.DepositParams,
    json_name: "depositParams",
    deprecated: false
  )

  field(:tally_params, 3,
    type: Cosmos.Gov.V1beta1.TallyParams,
    json_name: "tallyParams",
    deprecated: false
  )
end

defmodule Cosmos.Gov.V1beta1.QueryDepositRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId")
  field(:depositor, 2, type: :string, deprecated: false)
end

defmodule Cosmos.Gov.V1beta1.QueryDepositResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:deposit, 1, type: Cosmos.Gov.V1beta1.Deposit, deprecated: false)
end

defmodule Cosmos.Gov.V1beta1.QueryDepositsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId")
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Gov.V1beta1.QueryDepositsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:deposits, 1, repeated: true, type: Cosmos.Gov.V1beta1.Deposit, deprecated: false)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Gov.V1beta1.QueryTallyResultRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId")
end

defmodule Cosmos.Gov.V1beta1.QueryTallyResultResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tally, 1, type: Cosmos.Gov.V1beta1.TallyResult, deprecated: false)
end

defmodule Cosmos.Gov.V1beta1.Query.Service do
  @moduledoc false

  use GRPC.Service, name: "cosmos.gov.v1beta1.Query", protoc_gen_elixir_version: "0.13.0"

  rpc(
    :Proposal,
    Cosmos.Gov.V1beta1.QueryProposalRequest,
    Cosmos.Gov.V1beta1.QueryProposalResponse
  )

  rpc(
    :Proposals,
    Cosmos.Gov.V1beta1.QueryProposalsRequest,
    Cosmos.Gov.V1beta1.QueryProposalsResponse
  )

  rpc(:Vote, Cosmos.Gov.V1beta1.QueryVoteRequest, Cosmos.Gov.V1beta1.QueryVoteResponse)

  rpc(:Votes, Cosmos.Gov.V1beta1.QueryVotesRequest, Cosmos.Gov.V1beta1.QueryVotesResponse)

  rpc(:Params, Cosmos.Gov.V1beta1.QueryParamsRequest, Cosmos.Gov.V1beta1.QueryParamsResponse)

  rpc(:Deposit, Cosmos.Gov.V1beta1.QueryDepositRequest, Cosmos.Gov.V1beta1.QueryDepositResponse)

  rpc(
    :Deposits,
    Cosmos.Gov.V1beta1.QueryDepositsRequest,
    Cosmos.Gov.V1beta1.QueryDepositsResponse
  )

  rpc(
    :TallyResult,
    Cosmos.Gov.V1beta1.QueryTallyResultRequest,
    Cosmos.Gov.V1beta1.QueryTallyResultResponse
  )
end

defmodule Cosmos.Gov.V1beta1.Query.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.Gov.V1beta1.Query.Service
end
