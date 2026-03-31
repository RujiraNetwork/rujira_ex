defmodule Cosmos.Gov.V1.MsgSubmitProposal do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:messages, 1, repeated: true, type: Google.Protobuf.Any)

  field(:initial_deposit, 2,
    repeated: true,
    type: Cosmos.Base.V1beta1.Coin,
    json_name: "initialDeposit",
    deprecated: false
  )

  field(:proposer, 3, type: :string, deprecated: false)
  field(:metadata, 4, type: :string)
  field(:title, 5, type: :string)
  field(:summary, 6, type: :string)
  field(:expedited, 7, type: :bool)
end

defmodule Cosmos.Gov.V1.MsgSubmitProposalResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId")
end

defmodule Cosmos.Gov.V1.MsgExecLegacyContent do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:content, 1, type: Google.Protobuf.Any, deprecated: false)
  field(:authority, 2, type: :string)
end

defmodule Cosmos.Gov.V1.MsgExecLegacyContentResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Gov.V1.MsgVote do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId", deprecated: false)
  field(:voter, 2, type: :string, deprecated: false)
  field(:option, 3, type: Cosmos.Gov.V1.VoteOption, enum: true)
  field(:metadata, 4, type: :string)
end

defmodule Cosmos.Gov.V1.MsgVoteResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Gov.V1.MsgVoteWeighted do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId", deprecated: false)
  field(:voter, 2, type: :string, deprecated: false)
  field(:options, 3, repeated: true, type: Cosmos.Gov.V1.WeightedVoteOption)
  field(:metadata, 4, type: :string)
end

defmodule Cosmos.Gov.V1.MsgVoteWeightedResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Gov.V1.MsgDeposit do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId", deprecated: false)
  field(:depositor, 2, type: :string, deprecated: false)
  field(:amount, 3, repeated: true, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
end

defmodule Cosmos.Gov.V1.MsgDepositResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Gov.V1.MsgUpdateParams do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:authority, 1, type: :string, deprecated: false)
  field(:params, 2, type: Cosmos.Gov.V1.Params, deprecated: false)
end

defmodule Cosmos.Gov.V1.MsgUpdateParamsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Gov.V1.MsgCancelProposal do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId", deprecated: false)
  field(:proposer, 2, type: :string, deprecated: false)
end

defmodule Cosmos.Gov.V1.MsgCancelProposalResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId", deprecated: false)

  field(:canceled_time, 2,
    type: Google.Protobuf.Timestamp,
    json_name: "canceledTime",
    deprecated: false
  )

  field(:canceled_height, 3, type: :uint64, json_name: "canceledHeight")
end

defmodule Cosmos.Gov.V1.Msg.Service do
  @moduledoc false

  use GRPC.Service, name: "cosmos.gov.v1.Msg", protoc_gen_elixir_version: "0.13.0"

  rpc(:SubmitProposal, Cosmos.Gov.V1.MsgSubmitProposal, Cosmos.Gov.V1.MsgSubmitProposalResponse)

  rpc(
    :ExecLegacyContent,
    Cosmos.Gov.V1.MsgExecLegacyContent,
    Cosmos.Gov.V1.MsgExecLegacyContentResponse
  )

  rpc(:Vote, Cosmos.Gov.V1.MsgVote, Cosmos.Gov.V1.MsgVoteResponse)

  rpc(:VoteWeighted, Cosmos.Gov.V1.MsgVoteWeighted, Cosmos.Gov.V1.MsgVoteWeightedResponse)

  rpc(:Deposit, Cosmos.Gov.V1.MsgDeposit, Cosmos.Gov.V1.MsgDepositResponse)

  rpc(:UpdateParams, Cosmos.Gov.V1.MsgUpdateParams, Cosmos.Gov.V1.MsgUpdateParamsResponse)

  rpc(:CancelProposal, Cosmos.Gov.V1.MsgCancelProposal, Cosmos.Gov.V1.MsgCancelProposalResponse)
end

defmodule Cosmos.Gov.V1.Msg.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.Gov.V1.Msg.Service
end
