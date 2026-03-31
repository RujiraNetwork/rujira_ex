defmodule Cosmos.Upgrade.V1beta1.MsgSoftwareUpgrade do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:authority, 1, type: :string, deprecated: false)
  field(:plan, 2, type: Cosmos.Upgrade.V1beta1.Plan, deprecated: false)
end

defmodule Cosmos.Upgrade.V1beta1.MsgSoftwareUpgradeResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Upgrade.V1beta1.MsgCancelUpgrade do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:authority, 1, type: :string, deprecated: false)
end

defmodule Cosmos.Upgrade.V1beta1.MsgCancelUpgradeResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Upgrade.V1beta1.Msg.Service do
  @moduledoc false

  use GRPC.Service, name: "cosmos.upgrade.v1beta1.Msg", protoc_gen_elixir_version: "0.13.0"

  rpc(
    :SoftwareUpgrade,
    Cosmos.Upgrade.V1beta1.MsgSoftwareUpgrade,
    Cosmos.Upgrade.V1beta1.MsgSoftwareUpgradeResponse
  )

  rpc(
    :CancelUpgrade,
    Cosmos.Upgrade.V1beta1.MsgCancelUpgrade,
    Cosmos.Upgrade.V1beta1.MsgCancelUpgradeResponse
  )
end

defmodule Cosmos.Upgrade.V1beta1.Msg.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.Upgrade.V1beta1.Msg.Service
end
