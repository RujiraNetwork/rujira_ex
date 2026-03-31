defmodule Cosmos.Base.Node.V1beta1.ConfigRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Base.Node.V1beta1.ConfigResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:minimum_gas_price, 1, type: :string, json_name: "minimumGasPrice")
  field(:pruning_keep_recent, 2, type: :string, json_name: "pruningKeepRecent")
  field(:pruning_interval, 3, type: :string, json_name: "pruningInterval")
  field(:halt_height, 4, type: :uint64, json_name: "haltHeight")
end

defmodule Cosmos.Base.Node.V1beta1.StatusRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Base.Node.V1beta1.StatusResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:earliest_store_height, 1, type: :uint64, json_name: "earliestStoreHeight")
  field(:height, 2, type: :uint64)
  field(:timestamp, 3, type: Google.Protobuf.Timestamp, deprecated: false)
  field(:app_hash, 4, type: :bytes, json_name: "appHash")
  field(:validator_hash, 5, type: :bytes, json_name: "validatorHash")
end

defmodule Cosmos.Base.Node.V1beta1.Service.Service do
  @moduledoc false

  use GRPC.Service, name: "cosmos.base.node.v1beta1.Service", protoc_gen_elixir_version: "0.13.0"

  rpc(:Config, Cosmos.Base.Node.V1beta1.ConfigRequest, Cosmos.Base.Node.V1beta1.ConfigResponse)

  rpc(:Status, Cosmos.Base.Node.V1beta1.StatusRequest, Cosmos.Base.Node.V1beta1.StatusResponse)
end

defmodule Cosmos.Base.Node.V1beta1.Service.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.Base.Node.V1beta1.Service.Service
end
