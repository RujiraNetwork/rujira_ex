defmodule Thorchain.Types.SendQuorumTxResult do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Thorchain.Types.SubscribeRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:event_types, 1, repeated: true, type: :string, json_name: "eventTypes")
end

defmodule Thorchain.Types.EventNotification do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:event_type, 1, type: :string, json_name: "eventType")
  field(:payload, 2, type: :bytes)
  field(:timestamp, 3, type: :int64)
end

defmodule Thorchain.Types.SendQuorumNetworkFeeResult do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Thorchain.Types.SendQuorumSolvencyResult do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Thorchain.Types.SendQuorumErrataTxResult do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Thorchain.Types.SendQuorumPriceFeedBatchResult do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Thorchain.Types.LocalhostBifrost.Service do
  @moduledoc false

  use GRPC.Service, name: "types.LocalhostBifrost", protoc_gen_elixir_version: "0.13.0"

  rpc(:SendQuorumTx, Thorchain.Common.QuorumTx, Thorchain.Types.SendQuorumTxResult)

  rpc(
    :SendQuorumNetworkFee,
    Thorchain.Common.QuorumNetworkFee,
    Thorchain.Types.SendQuorumNetworkFeeResult
  )

  rpc(
    :SendQuorumSolvency,
    Thorchain.Common.QuorumSolvency,
    Thorchain.Types.SendQuorumSolvencyResult
  )

  rpc(
    :SendQuorumErrataTx,
    Thorchain.Common.QuorumErrataTx,
    Thorchain.Types.SendQuorumErrataTxResult
  )

  rpc(
    :SendQuorumPriceFeedBatch,
    Thorchain.Common.QuorumPriceFeedBatch,
    Thorchain.Types.SendQuorumPriceFeedBatchResult
  )

  rpc(
    :SubscribeToEvents,
    Thorchain.Types.SubscribeRequest,
    stream(Thorchain.Types.EventNotification)
  )
end

defmodule Thorchain.Types.LocalhostBifrost.Stub do
  @moduledoc false

  use GRPC.Stub, service: Thorchain.Types.LocalhostBifrost.Service
end
