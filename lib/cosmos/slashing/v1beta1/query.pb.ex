defmodule Cosmos.Slashing.V1beta1.QueryParamsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Slashing.V1beta1.QueryParamsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:params, 1, type: Cosmos.Slashing.V1beta1.Params, deprecated: false)
end

defmodule Cosmos.Slashing.V1beta1.QuerySigningInfoRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:cons_address, 1, type: :string, json_name: "consAddress", deprecated: false)
end

defmodule Cosmos.Slashing.V1beta1.QuerySigningInfoResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:val_signing_info, 1,
    type: Cosmos.Slashing.V1beta1.ValidatorSigningInfo,
    json_name: "valSigningInfo",
    deprecated: false
  )
end

defmodule Cosmos.Slashing.V1beta1.QuerySigningInfosRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pagination, 1, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Slashing.V1beta1.QuerySigningInfosResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:info, 1,
    repeated: true,
    type: Cosmos.Slashing.V1beta1.ValidatorSigningInfo,
    deprecated: false
  )

  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Slashing.V1beta1.Query.Service do
  @moduledoc false

  use GRPC.Service, name: "cosmos.slashing.v1beta1.Query", protoc_gen_elixir_version: "0.13.0"

  rpc(
    :Params,
    Cosmos.Slashing.V1beta1.QueryParamsRequest,
    Cosmos.Slashing.V1beta1.QueryParamsResponse
  )

  rpc(
    :SigningInfo,
    Cosmos.Slashing.V1beta1.QuerySigningInfoRequest,
    Cosmos.Slashing.V1beta1.QuerySigningInfoResponse
  )

  rpc(
    :SigningInfos,
    Cosmos.Slashing.V1beta1.QuerySigningInfosRequest,
    Cosmos.Slashing.V1beta1.QuerySigningInfosResponse
  )
end

defmodule Cosmos.Slashing.V1beta1.Query.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.Slashing.V1beta1.Query.Service
end
