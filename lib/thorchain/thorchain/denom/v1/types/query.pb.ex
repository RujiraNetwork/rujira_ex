defmodule Thorchain.Thorchain.Denom.V1.QueryDenomAdminRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:denom, 1, type: :string, deprecated: false)
end

defmodule Thorchain.Thorchain.Denom.V1.QueryDenomAdminResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:admin, 1, type: :string, deprecated: false)
end

defmodule Thorchain.Thorchain.Denom.V1.Query.Service do
  @moduledoc false

  use GRPC.Service, name: "thorchain.denom.v1.Query", protoc_gen_elixir_version: "0.13.0"

  rpc(
    :DenomAdmin,
    Thorchain.Thorchain.Denom.V1.QueryDenomAdminRequest,
    Thorchain.Thorchain.Denom.V1.QueryDenomAdminResponse
  )
end

defmodule Thorchain.Thorchain.Denom.V1.Query.Stub do
  @moduledoc false

  use GRPC.Stub, service: Thorchain.Thorchain.Denom.V1.Query.Service
end
