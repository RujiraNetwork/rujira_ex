defmodule Cosmos.App.V1alpha1.QueryConfigRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.App.V1alpha1.QueryConfigResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:config, 1, type: Cosmos.App.V1alpha1.Config)
end

defmodule Cosmos.App.V1alpha1.Query.Service do
  @moduledoc false

  use GRPC.Service, name: "cosmos.app.v1alpha1.Query", protoc_gen_elixir_version: "0.13.0"

  rpc(:Config, Cosmos.App.V1alpha1.QueryConfigRequest, Cosmos.App.V1alpha1.QueryConfigResponse)
end

defmodule Cosmos.App.V1alpha1.Query.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.App.V1alpha1.Query.Service
end
