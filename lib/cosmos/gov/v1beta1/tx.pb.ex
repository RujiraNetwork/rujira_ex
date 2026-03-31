defmodule Cosmos.Gov.V1beta1.MsgSubmitProposal do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:content, 1, type: Google.Protobuf.Any, deprecated: false)

  field(:initial_deposit, 2,
    repeated: true,
    type: Cosmos.Base.V1beta1.Coin,
    json_name: "initialDeposit",
    deprecated: false
  )

  field(:proposer, 3, type: :string, deprecated: false)
end

defmodule Cosmos.Gov.V1beta1.MsgSubmitProposalResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId", deprecated: false)
end

defmodule Cosmos.Gov.V1beta1.MsgVote do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId")
  field(:voter, 2, type: :string, deprecated: false)
  field(:option, 3, type: Cosmos.Gov.V1beta1.VoteOption, enum: true)
end

defmodule Cosmos.Gov.V1beta1.MsgVoteResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Gov.V1beta1.MsgVoteWeighted do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId", deprecated: false)
  field(:voter, 2, type: :string, deprecated: false)

  field(:options, 3,
    repeated: true,
    type: Cosmos.Gov.V1beta1.WeightedVoteOption,
    deprecated: false
  )
end

defmodule Cosmos.Gov.V1beta1.MsgVoteWeightedResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Gov.V1beta1.MsgDeposit do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId", deprecated: false)
  field(:depositor, 2, type: :string, deprecated: false)
  field(:amount, 3, repeated: true, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
end

defmodule Cosmos.Gov.V1beta1.MsgDepositResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Gov.V1beta1.Msg.Service do
  @moduledoc false

  use GRPC.Service, name: "cosmos.gov.v1beta1.Msg", protoc_gen_elixir_version: "0.13.0"

  rpc(
    :SubmitProposal,
    Cosmos.Gov.V1beta1.MsgSubmitProposal,
    Cosmos.Gov.V1beta1.MsgSubmitProposalResponse
  )

  rpc(:Vote, Cosmos.Gov.V1beta1.MsgVote, Cosmos.Gov.V1beta1.MsgVoteResponse)

  rpc(
    :VoteWeighted,
    Cosmos.Gov.V1beta1.MsgVoteWeighted,
    Cosmos.Gov.V1beta1.MsgVoteWeightedResponse
  )

  rpc(:Deposit, Cosmos.Gov.V1beta1.MsgDeposit, Cosmos.Gov.V1beta1.MsgDepositResponse)
end

defmodule Cosmos.Gov.V1beta1.Msg.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.Gov.V1beta1.Msg.Service
end
