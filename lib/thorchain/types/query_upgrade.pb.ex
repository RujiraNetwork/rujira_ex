defmodule Thorchain.Types.QueryUpgradeProposalRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:name, 1, type: :string)
  field(:height, 2, type: :string)
end

defmodule Thorchain.Types.QueryUpgradeProposalResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:name, 1, type: :string, deprecated: false)
  field(:height, 2, type: :int64, deprecated: false)
  field(:info, 3, type: :string, deprecated: false)
  field(:approved, 4, type: :bool, deprecated: false)
  field(:approved_percent, 5, type: :string, json_name: "approvedPercent")

  field(:validators_to_quorum, 6,
    type: :int64,
    json_name: "validatorsToQuorum",
    deprecated: false
  )

  field(:approvers, 7, repeated: true, type: :string, deprecated: false)
  field(:rejecters, 8, repeated: true, type: :string, deprecated: false)
end

defmodule Thorchain.Types.QueryUpgradeProposalsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
end

defmodule Thorchain.Types.QueryUpgradeProposalsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:upgrade_proposals, 1,
    repeated: true,
    type: Thorchain.Types.QueryUpgradeProposalResponse,
    json_name: "upgradeProposals"
  )
end

defmodule Thorchain.Types.QueryUpgradeVotesRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:name, 1, type: :string)
  field(:height, 2, type: :string)
end

defmodule Thorchain.Types.UpgradeVote do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:node_address, 1, type: :string, json_name: "nodeAddress", deprecated: false)
  field(:vote, 2, type: :string, deprecated: false)
end

defmodule Thorchain.Types.QueryUpgradeVotesResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:upgrade_votes, 1,
    repeated: true,
    type: Thorchain.Types.UpgradeVote,
    json_name: "upgradeVotes"
  )
end
