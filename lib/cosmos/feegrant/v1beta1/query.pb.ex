defmodule Cosmos.Feegrant.V1beta1.QueryAllowanceRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:granter, 1, type: :string, deprecated: false)
  field(:grantee, 2, type: :string, deprecated: false)
end

defmodule Cosmos.Feegrant.V1beta1.QueryAllowanceResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:allowance, 1, type: Cosmos.Feegrant.V1beta1.Grant)
end

defmodule Cosmos.Feegrant.V1beta1.QueryAllowancesRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:grantee, 1, type: :string, deprecated: false)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Feegrant.V1beta1.QueryAllowancesResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:allowances, 1, repeated: true, type: Cosmos.Feegrant.V1beta1.Grant)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Feegrant.V1beta1.QueryAllowancesByGranterRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:granter, 1, type: :string, deprecated: false)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Feegrant.V1beta1.QueryAllowancesByGranterResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:allowances, 1, repeated: true, type: Cosmos.Feegrant.V1beta1.Grant)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Feegrant.V1beta1.Query.Service do
  @moduledoc false

  use GRPC.Service, name: "cosmos.feegrant.v1beta1.Query", protoc_gen_elixir_version: "0.13.0"

  rpc(
    :Allowance,
    Cosmos.Feegrant.V1beta1.QueryAllowanceRequest,
    Cosmos.Feegrant.V1beta1.QueryAllowanceResponse
  )

  rpc(
    :Allowances,
    Cosmos.Feegrant.V1beta1.QueryAllowancesRequest,
    Cosmos.Feegrant.V1beta1.QueryAllowancesResponse
  )

  rpc(
    :AllowancesByGranter,
    Cosmos.Feegrant.V1beta1.QueryAllowancesByGranterRequest,
    Cosmos.Feegrant.V1beta1.QueryAllowancesByGranterResponse
  )
end

defmodule Cosmos.Feegrant.V1beta1.Query.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.Feegrant.V1beta1.Query.Service
end
