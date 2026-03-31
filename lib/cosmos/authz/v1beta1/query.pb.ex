defmodule Cosmos.Authz.V1beta1.QueryGrantsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:granter, 1, type: :string, deprecated: false)
  field(:grantee, 2, type: :string, deprecated: false)
  field(:msg_type_url, 3, type: :string, json_name: "msgTypeUrl")
  field(:pagination, 4, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Authz.V1beta1.QueryGrantsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:grants, 1, repeated: true, type: Cosmos.Authz.V1beta1.Grant)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Authz.V1beta1.QueryGranterGrantsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:granter, 1, type: :string, deprecated: false)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Authz.V1beta1.QueryGranterGrantsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:grants, 1, repeated: true, type: Cosmos.Authz.V1beta1.GrantAuthorization)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Authz.V1beta1.QueryGranteeGrantsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:grantee, 1, type: :string, deprecated: false)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Authz.V1beta1.QueryGranteeGrantsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:grants, 1, repeated: true, type: Cosmos.Authz.V1beta1.GrantAuthorization)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Authz.V1beta1.Query.Service do
  @moduledoc false

  use GRPC.Service, name: "cosmos.authz.v1beta1.Query", protoc_gen_elixir_version: "0.13.0"

  rpc(:Grants, Cosmos.Authz.V1beta1.QueryGrantsRequest, Cosmos.Authz.V1beta1.QueryGrantsResponse)

  rpc(
    :GranterGrants,
    Cosmos.Authz.V1beta1.QueryGranterGrantsRequest,
    Cosmos.Authz.V1beta1.QueryGranterGrantsResponse
  )

  rpc(
    :GranteeGrants,
    Cosmos.Authz.V1beta1.QueryGranteeGrantsRequest,
    Cosmos.Authz.V1beta1.QueryGranteeGrantsResponse
  )
end

defmodule Cosmos.Authz.V1beta1.Query.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.Authz.V1beta1.Query.Service
end
