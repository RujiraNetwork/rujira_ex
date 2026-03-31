defmodule Cosmos.Mint.V1beta1.QueryParamsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Mint.V1beta1.QueryParamsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:params, 1, type: Cosmos.Mint.V1beta1.Params, deprecated: false)
end

defmodule Cosmos.Mint.V1beta1.QueryInflationRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Mint.V1beta1.QueryInflationResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:inflation, 1, type: :bytes, deprecated: false)
end

defmodule Cosmos.Mint.V1beta1.QueryAnnualProvisionsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Mint.V1beta1.QueryAnnualProvisionsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:annual_provisions, 1, type: :bytes, json_name: "annualProvisions", deprecated: false)
end

defmodule Cosmos.Mint.V1beta1.Query.Service do
  @moduledoc false

  use GRPC.Service, name: "cosmos.mint.v1beta1.Query", protoc_gen_elixir_version: "0.13.0"

  rpc(:Params, Cosmos.Mint.V1beta1.QueryParamsRequest, Cosmos.Mint.V1beta1.QueryParamsResponse)

  rpc(
    :Inflation,
    Cosmos.Mint.V1beta1.QueryInflationRequest,
    Cosmos.Mint.V1beta1.QueryInflationResponse
  )

  rpc(
    :AnnualProvisions,
    Cosmos.Mint.V1beta1.QueryAnnualProvisionsRequest,
    Cosmos.Mint.V1beta1.QueryAnnualProvisionsResponse
  )
end

defmodule Cosmos.Mint.V1beta1.Query.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.Mint.V1beta1.Query.Service
end
