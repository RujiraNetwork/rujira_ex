defmodule Cosmos.Params.V1beta1.QueryParamsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:subspace, 1, type: :string)
  field(:key, 2, type: :string)
end

defmodule Cosmos.Params.V1beta1.QueryParamsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:param, 1, type: Cosmos.Params.V1beta1.ParamChange, deprecated: false)
end

defmodule Cosmos.Params.V1beta1.QuerySubspacesRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Params.V1beta1.QuerySubspacesResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:subspaces, 1, repeated: true, type: Cosmos.Params.V1beta1.Subspace)
end

defmodule Cosmos.Params.V1beta1.Subspace do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:subspace, 1, type: :string)
  field(:keys, 2, repeated: true, type: :string)
end

defmodule Cosmos.Params.V1beta1.Query.Service do
  @moduledoc false

  use GRPC.Service, name: "cosmos.params.v1beta1.Query", protoc_gen_elixir_version: "0.13.0"

  rpc(
    :Params,
    Cosmos.Params.V1beta1.QueryParamsRequest,
    Cosmos.Params.V1beta1.QueryParamsResponse
  )

  rpc(
    :Subspaces,
    Cosmos.Params.V1beta1.QuerySubspacesRequest,
    Cosmos.Params.V1beta1.QuerySubspacesResponse
  )
end

defmodule Cosmos.Params.V1beta1.Query.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.Params.V1beta1.Query.Service
end
