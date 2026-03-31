defmodule Cosmos.Group.V1.EventCreateGroup do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:group_id, 1, type: :uint64, json_name: "groupId")
end

defmodule Cosmos.Group.V1.EventUpdateGroup do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:group_id, 1, type: :uint64, json_name: "groupId")
end

defmodule Cosmos.Group.V1.EventCreateGroupPolicy do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)
end

defmodule Cosmos.Group.V1.EventUpdateGroupPolicy do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)
end

defmodule Cosmos.Group.V1.EventSubmitProposal do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId")
end

defmodule Cosmos.Group.V1.EventWithdrawProposal do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId")
end

defmodule Cosmos.Group.V1.EventVote do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId")
end

defmodule Cosmos.Group.V1.EventExec do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId")
  field(:result, 2, type: Cosmos.Group.V1.ProposalExecutorResult, enum: true)
  field(:logs, 3, type: :string)
end

defmodule Cosmos.Group.V1.EventLeaveGroup do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:group_id, 1, type: :uint64, json_name: "groupId")
  field(:address, 2, type: :string, deprecated: false)
end

defmodule Cosmos.Group.V1.EventProposalPruned do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proposal_id, 1, type: :uint64, json_name: "proposalId")
  field(:status, 2, type: Cosmos.Group.V1.ProposalStatus, enum: true)
  field(:tally_result, 3, type: Cosmos.Group.V1.TallyResult, json_name: "tallyResult")
end
