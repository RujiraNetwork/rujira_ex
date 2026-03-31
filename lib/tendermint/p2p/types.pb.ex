defmodule Tendermint.P2p.NetAddress do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:id, 1, type: :string, deprecated: false)
  field(:ip, 2, type: :string, deprecated: false)
  field(:port, 3, type: :uint32)
end

defmodule Tendermint.P2p.ProtocolVersion do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:p2p, 1, type: :uint64, deprecated: false)
  field(:block, 2, type: :uint64)
  field(:app, 3, type: :uint64)
end

defmodule Tendermint.P2p.DefaultNodeInfo do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:protocol_version, 1,
    type: Tendermint.P2p.ProtocolVersion,
    json_name: "protocolVersion",
    deprecated: false
  )

  field(:default_node_id, 2, type: :string, json_name: "defaultNodeId", deprecated: false)
  field(:listen_addr, 3, type: :string, json_name: "listenAddr")
  field(:network, 4, type: :string)
  field(:version, 5, type: :string)
  field(:channels, 6, type: :bytes)
  field(:moniker, 7, type: :string)
  field(:other, 8, type: Tendermint.P2p.DefaultNodeInfoOther, deprecated: false)
end

defmodule Tendermint.P2p.DefaultNodeInfoOther do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx_index, 1, type: :string, json_name: "txIndex")
  field(:rpc_address, 2, type: :string, json_name: "rpcAddress", deprecated: false)
end
