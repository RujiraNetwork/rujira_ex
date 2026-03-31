defmodule Cosmos.Tx.V1beta1.OrderBy do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:ORDER_BY_UNSPECIFIED, 0)
  field(:ORDER_BY_ASC, 1)
  field(:ORDER_BY_DESC, 2)
end

defmodule Cosmos.Tx.V1beta1.BroadcastMode do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:BROADCAST_MODE_UNSPECIFIED, 0)
  field(:BROADCAST_MODE_BLOCK, 1)
  field(:BROADCAST_MODE_SYNC, 2)
  field(:BROADCAST_MODE_ASYNC, 3)
end

defmodule Cosmos.Tx.V1beta1.GetTxsEventRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:events, 1, repeated: true, type: :string, deprecated: true)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageRequest, deprecated: true)
  field(:order_by, 3, type: Cosmos.Tx.V1beta1.OrderBy, json_name: "orderBy", enum: true)
  field(:page, 4, type: :uint64)
  field(:limit, 5, type: :uint64)
  field(:query, 6, type: :string)
end

defmodule Cosmos.Tx.V1beta1.GetTxsEventResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:txs, 1, repeated: true, type: Cosmos.Tx.V1beta1.Tx)

  field(:tx_responses, 2,
    repeated: true,
    type: Cosmos.Base.Abci.V1beta1.TxResponse,
    json_name: "txResponses"
  )

  field(:pagination, 3, type: Cosmos.Base.Query.V1beta1.PageResponse, deprecated: true)
  field(:total, 4, type: :uint64)
end

defmodule Cosmos.Tx.V1beta1.BroadcastTxRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx_bytes, 1, type: :bytes, json_name: "txBytes")
  field(:mode, 2, type: Cosmos.Tx.V1beta1.BroadcastMode, enum: true)
end

defmodule Cosmos.Tx.V1beta1.BroadcastTxResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx_response, 1, type: Cosmos.Base.Abci.V1beta1.TxResponse, json_name: "txResponse")
end

defmodule Cosmos.Tx.V1beta1.SimulateRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx, 1, type: Cosmos.Tx.V1beta1.Tx, deprecated: true)
  field(:tx_bytes, 2, type: :bytes, json_name: "txBytes")
end

defmodule Cosmos.Tx.V1beta1.SimulateResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:gas_info, 1, type: Cosmos.Base.Abci.V1beta1.GasInfo, json_name: "gasInfo")
  field(:result, 2, type: Cosmos.Base.Abci.V1beta1.Result)
end

defmodule Cosmos.Tx.V1beta1.GetTxRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:hash, 1, type: :string)
end

defmodule Cosmos.Tx.V1beta1.GetTxResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx, 1, type: Cosmos.Tx.V1beta1.Tx)
  field(:tx_response, 2, type: Cosmos.Base.Abci.V1beta1.TxResponse, json_name: "txResponse")
end

defmodule Cosmos.Tx.V1beta1.GetBlockWithTxsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :int64)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Tx.V1beta1.GetBlockWithTxsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:txs, 1, repeated: true, type: Cosmos.Tx.V1beta1.Tx)
  field(:block_id, 2, type: Tendermint.Types.BlockID, json_name: "blockId")
  field(:block, 3, type: Tendermint.Types.Block)
  field(:pagination, 4, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Tx.V1beta1.TxDecodeRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx_bytes, 1, type: :bytes, json_name: "txBytes")
end

defmodule Cosmos.Tx.V1beta1.TxDecodeResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx, 1, type: Cosmos.Tx.V1beta1.Tx)
end

defmodule Cosmos.Tx.V1beta1.TxEncodeRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx, 1, type: Cosmos.Tx.V1beta1.Tx)
end

defmodule Cosmos.Tx.V1beta1.TxEncodeResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx_bytes, 1, type: :bytes, json_name: "txBytes")
end

defmodule Cosmos.Tx.V1beta1.TxEncodeAminoRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:amino_json, 1, type: :string, json_name: "aminoJson")
end

defmodule Cosmos.Tx.V1beta1.TxEncodeAminoResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:amino_binary, 1, type: :bytes, json_name: "aminoBinary")
end

defmodule Cosmos.Tx.V1beta1.TxDecodeAminoRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:amino_binary, 1, type: :bytes, json_name: "aminoBinary")
end

defmodule Cosmos.Tx.V1beta1.TxDecodeAminoResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:amino_json, 1, type: :string, json_name: "aminoJson")
end

defmodule Cosmos.Tx.V1beta1.Service.Service do
  @moduledoc false

  use GRPC.Service, name: "cosmos.tx.v1beta1.Service", protoc_gen_elixir_version: "0.13.0"

  rpc(:Simulate, Cosmos.Tx.V1beta1.SimulateRequest, Cosmos.Tx.V1beta1.SimulateResponse)

  rpc(:GetTx, Cosmos.Tx.V1beta1.GetTxRequest, Cosmos.Tx.V1beta1.GetTxResponse)

  rpc(:BroadcastTx, Cosmos.Tx.V1beta1.BroadcastTxRequest, Cosmos.Tx.V1beta1.BroadcastTxResponse)

  rpc(:GetTxsEvent, Cosmos.Tx.V1beta1.GetTxsEventRequest, Cosmos.Tx.V1beta1.GetTxsEventResponse)

  rpc(
    :GetBlockWithTxs,
    Cosmos.Tx.V1beta1.GetBlockWithTxsRequest,
    Cosmos.Tx.V1beta1.GetBlockWithTxsResponse
  )

  rpc(:TxDecode, Cosmos.Tx.V1beta1.TxDecodeRequest, Cosmos.Tx.V1beta1.TxDecodeResponse)

  rpc(:TxEncode, Cosmos.Tx.V1beta1.TxEncodeRequest, Cosmos.Tx.V1beta1.TxEncodeResponse)

  rpc(
    :TxEncodeAmino,
    Cosmos.Tx.V1beta1.TxEncodeAminoRequest,
    Cosmos.Tx.V1beta1.TxEncodeAminoResponse
  )

  rpc(
    :TxDecodeAmino,
    Cosmos.Tx.V1beta1.TxDecodeAminoRequest,
    Cosmos.Tx.V1beta1.TxDecodeAminoResponse
  )
end

defmodule Cosmos.Tx.V1beta1.Service.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.Tx.V1beta1.Service.Service
end
