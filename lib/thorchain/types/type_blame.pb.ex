defmodule Thorchain.Types.Node do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pubkey, 1, type: :string)
  field(:blame_data, 2, type: :bytes, json_name: "blameData")
  field(:blame_signature, 3, type: :bytes, json_name: "blameSignature")
end

defmodule Thorchain.Types.Blame do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:fail_reason, 1, type: :string, json_name: "failReason")
  field(:is_unicast, 2, type: :bool, json_name: "isUnicast")

  field(:blame_nodes, 3,
    repeated: true,
    type: Thorchain.Types.Node,
    json_name: "blameNodes",
    deprecated: false
  )

  field(:round, 4, type: :string)
end
