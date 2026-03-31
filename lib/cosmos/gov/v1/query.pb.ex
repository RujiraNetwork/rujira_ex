defmodule Cosmos.Gov.V1.QueryConstitutionRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Gov.V1.QueryConstitutionResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:constitution, 1, type: :string)
end

defmodule Cosmos.Gov.V1.QueryProposalRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId")
end

defmodule Cosmos.Gov.V1.QueryProposalResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal, 1, type: Cosmos.Gov.V1.Proposal)
end

defmodule Cosmos.Gov.V1.QueryProposalsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_status, 1,
    type: Cosmos.Gov.V1.ProposalStatus,
    json_name: "proposalStatus",
    enum: true
  )

  field(:voter, 2, type: :string, deprecated: false)
  field(:depositor, 3, type: :string, deprecated: false)
  field(:pagination, 4, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Gov.V1.QueryProposalsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposals, 1, repeated: true, type: Cosmos.Gov.V1.Proposal)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Gov.V1.QueryVoteRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId")
  field(:voter, 2, type: :string, deprecated: false)
end

defmodule Cosmos.Gov.V1.QueryVoteResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:vote, 1, type: Cosmos.Gov.V1.Vote)
end

defmodule Cosmos.Gov.V1.QueryVotesRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId")
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Gov.V1.QueryVotesResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:votes, 1, repeated: true, type: Cosmos.Gov.V1.Vote)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Gov.V1.QueryParamsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:params_type, 1, type: :string, json_name: "paramsType")
end

defmodule Cosmos.Gov.V1.QueryParamsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:voting_params, 1,
    type: Cosmos.Gov.V1.VotingParams,
    json_name: "votingParams",
    deprecated: true
  )

  field(:deposit_params, 2,
    type: Cosmos.Gov.V1.DepositParams,
    json_name: "depositParams",
    deprecated: true
  )

  field(:tally_params, 3,
    type: Cosmos.Gov.V1.TallyParams,
    json_name: "tallyParams",
    deprecated: true
  )

  field(:params, 4, type: Cosmos.Gov.V1.Params)
end

defmodule Cosmos.Gov.V1.QueryDepositRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId")
  field(:depositor, 2, type: :string, deprecated: false)
end

defmodule Cosmos.Gov.V1.QueryDepositResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:deposit, 1, type: Cosmos.Gov.V1.Deposit)
end

defmodule Cosmos.Gov.V1.QueryDepositsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId")
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Gov.V1.QueryDepositsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:deposits, 1, repeated: true, type: Cosmos.Gov.V1.Deposit)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Gov.V1.QueryTallyResultRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId")
end

defmodule Cosmos.Gov.V1.QueryTallyResultResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tally, 1, type: Cosmos.Gov.V1.TallyResult)
end

defmodule Cosmos.Gov.V1.Query.Service do
  @moduledoc false

  use GRPC.Service, name: "cosmos.gov.v1.Query", protoc_gen_elixir_version: "0.13.0"

  rpc(
    :Constitution,
    Cosmos.Gov.V1.QueryConstitutionRequest,
    Cosmos.Gov.V1.QueryConstitutionResponse
  )

  rpc(:Proposal, Cosmos.Gov.V1.QueryProposalRequest, Cosmos.Gov.V1.QueryProposalResponse)

  rpc(:Proposals, Cosmos.Gov.V1.QueryProposalsRequest, Cosmos.Gov.V1.QueryProposalsResponse)

  rpc(:Vote, Cosmos.Gov.V1.QueryVoteRequest, Cosmos.Gov.V1.QueryVoteResponse)

  rpc(:Votes, Cosmos.Gov.V1.QueryVotesRequest, Cosmos.Gov.V1.QueryVotesResponse)

  rpc(:Params, Cosmos.Gov.V1.QueryParamsRequest, Cosmos.Gov.V1.QueryParamsResponse)

  rpc(:Deposit, Cosmos.Gov.V1.QueryDepositRequest, Cosmos.Gov.V1.QueryDepositResponse)

  rpc(:Deposits, Cosmos.Gov.V1.QueryDepositsRequest, Cosmos.Gov.V1.QueryDepositsResponse)

  rpc(:TallyResult, Cosmos.Gov.V1.QueryTallyResultRequest, Cosmos.Gov.V1.QueryTallyResultResponse)
end

defmodule Cosmos.Gov.V1.Query.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.Gov.V1.Query.Service
end
