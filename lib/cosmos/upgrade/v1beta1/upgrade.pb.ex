defmodule Cosmos.Upgrade.V1beta1.Plan do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:name, 1, type: :string)
  field(:time, 2, type: Google.Protobuf.Timestamp, deprecated: true)
  field(:height, 3, type: :int64)
  field(:info, 4, type: :string)

  field(:upgraded_client_state, 5,
    type: Google.Protobuf.Any,
    json_name: "upgradedClientState",
    deprecated: true
  )
end

defmodule Cosmos.Upgrade.V1beta1.SoftwareUpgradeProposal do
  @moduledoc false

  use Protobuf, deprecated: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:title, 1, type: :string)
  field(:description, 2, type: :string)
  field(:plan, 3, type: Cosmos.Upgrade.V1beta1.Plan, deprecated: false)
end

defmodule Cosmos.Upgrade.V1beta1.CancelSoftwareUpgradeProposal do
  @moduledoc false

  use Protobuf, deprecated: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:title, 1, type: :string)
  field(:description, 2, type: :string)
end

defmodule Cosmos.Upgrade.V1beta1.ModuleVersion do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:name, 1, type: :string)
  field(:version, 2, type: :uint64)
end
