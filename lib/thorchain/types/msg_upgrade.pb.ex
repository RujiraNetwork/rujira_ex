defmodule Thorchain.Types.Upgrade do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :int64)
  field(:info, 2, type: :string)
end

defmodule Thorchain.Types.UpgradeProposal do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :int64)
  field(:info, 2, type: :string)
  field(:proposer, 3, type: :bytes, deprecated: false)
end

defmodule Thorchain.Types.MsgProposeUpgrade do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:name, 1, type: :string)
  field(:upgrade, 2, type: Thorchain.Types.Upgrade, deprecated: false)
  field(:signer, 3, type: :bytes, deprecated: false)
end

defmodule Thorchain.Types.MsgApproveUpgrade do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:name, 1, type: :string)
  field(:signer, 2, type: :bytes, deprecated: false)
end

defmodule Thorchain.Types.MsgRejectUpgrade do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:name, 1, type: :string)
  field(:signer, 2, type: :bytes, deprecated: false)
end
