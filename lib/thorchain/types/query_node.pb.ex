defmodule Thorchain.Types.QueryNodeRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string)
  field(:height, 2, type: :string)
end

defmodule Thorchain.Types.QueryNodeResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:node_address, 1, type: :string, json_name: "nodeAddress", deprecated: false)
  field(:status, 2, type: :string, deprecated: false)

  field(:pub_key_set, 3,
    type: Thorchain.Common.PubKeySet,
    json_name: "pubKeySet",
    deprecated: false
  )

  field(:validator_cons_pub_key, 4,
    type: :string,
    json_name: "validatorConsPubKey",
    deprecated: false
  )

  field(:peer_id, 5, type: :string, json_name: "peerId", deprecated: false)
  field(:active_block_height, 6, type: :int64, json_name: "activeBlockHeight", deprecated: false)
  field(:status_since, 7, type: :int64, json_name: "statusSince", deprecated: false)

  field(:node_operator_address, 8,
    type: :string,
    json_name: "nodeOperatorAddress",
    deprecated: false
  )

  field(:total_bond, 9, type: :string, json_name: "totalBond", deprecated: false)

  field(:bond_providers, 10,
    type: Thorchain.Types.NodeBondProviders,
    json_name: "bondProviders",
    deprecated: false
  )

  field(:signer_membership, 11,
    repeated: true,
    type: :string,
    json_name: "signerMembership",
    deprecated: false
  )

  field(:requested_to_leave, 12, type: :bool, json_name: "requestedToLeave", deprecated: false)
  field(:forced_to_leave, 13, type: :bool, json_name: "forcedToLeave", deprecated: false)
  field(:leave_height, 14, type: :int64, json_name: "leaveHeight", deprecated: false)
  field(:ip_address, 15, type: :string, json_name: "ipAddress", deprecated: false)
  field(:version, 16, type: :string, deprecated: false)
  field(:slash_points, 17, type: :int64, json_name: "slashPoints", deprecated: false)
  field(:jail, 18, type: Thorchain.Types.NodeJail, deprecated: false)
  field(:current_award, 19, type: :string, json_name: "currentAward", deprecated: false)

  field(:observe_chains, 20,
    repeated: true,
    type: Thorchain.Types.ChainHeight,
    json_name: "observeChains",
    deprecated: false
  )

  field(:preflight_status, 21,
    type: Thorchain.Types.NodePreflightStatus,
    json_name: "preflightStatus",
    deprecated: false
  )

  field(:maintenance, 22, type: :bool, deprecated: false)
  field(:missing_blocks, 23, type: :int64, json_name: "missingBlocks", deprecated: false)
end

defmodule Thorchain.Types.QueryNodesRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
end

defmodule Thorchain.Types.QueryNodesResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:nodes, 1, repeated: true, type: Thorchain.Types.QueryNodeResponse)
end

defmodule Thorchain.Types.NodeBondProviders do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:node_operator_fee, 1, type: :string, json_name: "nodeOperatorFee", deprecated: false)
  field(:providers, 2, repeated: true, type: Thorchain.Types.NodeBondProvider, deprecated: false)
end

defmodule Thorchain.Types.NodeBondProvider do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:bond_address, 1, type: :string, json_name: "bondAddress")
  field(:bond, 2, type: :string)
end

defmodule Thorchain.Types.NodeJail do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:release_height, 1, type: :int64, json_name: "releaseHeight")
  field(:reason, 2, type: :string)
end

defmodule Thorchain.Types.ChainHeight do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:chain, 1, type: :string, deprecated: false)
  field(:height, 2, type: :int64, deprecated: false)
end

defmodule Thorchain.Types.NodePreflightStatus do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:status, 1, type: :string, deprecated: false)
  field(:reason, 2, type: :string, deprecated: false)
  field(:code, 3, type: :int64, deprecated: false)
end
