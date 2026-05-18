defmodule Thorchain.Types.NodeStatus do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:Unknown, 0)
  field(:Whitelisted, 1)
  field(:Standby, 2)
  field(:Ready, 3)
  field(:Active, 4)
  field(:Disabled, 5)
end

defmodule Thorchain.Types.NodeType do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:TypeValidator, 0)
  field(:TypeVault, 1)
  field(:TypeUnknown, 2)
end

defmodule Thorchain.Types.NodeAccount do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:node_address, 1, type: :bytes, json_name: "nodeAddress", deprecated: false)
  field(:status, 2, type: Thorchain.Types.NodeStatus, enum: true)

  field(:pub_key_set, 3,
    type: Thorchain.Common.PubKeySet,
    json_name: "pubKeySet",
    deprecated: false
  )

  field(:validator_cons_pub_key, 4, type: :string, json_name: "validatorConsPubKey")
  field(:bond, 5, type: :string, deprecated: false)
  field(:active_block_height, 6, type: :int64, json_name: "activeBlockHeight")
  field(:bond_address, 7, type: :string, json_name: "bondAddress", deprecated: false)
  field(:status_since, 8, type: :int64, json_name: "statusSince")
  field(:signer_membership, 9, repeated: true, type: :string, json_name: "signerMembership")
  field(:requested_to_leave, 10, type: :bool, json_name: "requestedToLeave")
  field(:forced_to_leave, 11, type: :bool, json_name: "forcedToLeave")
  field(:leave_score, 12, type: :uint64, json_name: "leaveScore")
  field(:ip_address, 13, type: :string, json_name: "ipAddress", deprecated: false)
  field(:version, 14, type: :string)
  field(:type, 15, type: Thorchain.Types.NodeType, enum: true)
  field(:missing_blocks, 16, type: :uint64, json_name: "missingBlocks")
  field(:maintenance, 17, type: :bool)
end

defmodule Thorchain.Types.BondProvider do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:bond_address, 1, type: :bytes, json_name: "bondAddress", deprecated: false)
  field(:bond, 2, type: :string, deprecated: false)
end

defmodule Thorchain.Types.BondProviders do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:node_address, 1, type: :bytes, json_name: "nodeAddress", deprecated: false)
  field(:node_operator_fee, 2, type: :string, json_name: "nodeOperatorFee", deprecated: false)
  field(:providers, 3, repeated: true, type: Thorchain.Types.BondProvider, deprecated: false)
end

defmodule Thorchain.Types.MinJoinLast do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:last_changed_height, 1, type: :int64, json_name: "lastChangedHeight")
  field(:version, 2, type: :string)
end
