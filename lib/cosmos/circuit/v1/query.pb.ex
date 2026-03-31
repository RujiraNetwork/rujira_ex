defmodule Cosmos.Circuit.V1.QueryAccountRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string)
end

defmodule Cosmos.Circuit.V1.AccountResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:permission, 1, type: Cosmos.Circuit.V1.Permissions)
end

defmodule Cosmos.Circuit.V1.QueryAccountsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pagination, 1, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Circuit.V1.AccountsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:accounts, 1, repeated: true, type: Cosmos.Circuit.V1.GenesisAccountPermissions)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Circuit.V1.QueryDisabledListRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Circuit.V1.DisabledListResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:disabled_list, 1, repeated: true, type: :string, json_name: "disabledList")
end

defmodule Cosmos.Circuit.V1.Query.Service do
  @moduledoc false

  use GRPC.Service, name: "cosmos.circuit.v1.Query", protoc_gen_elixir_version: "0.13.0"

  rpc(:Account, Cosmos.Circuit.V1.QueryAccountRequest, Cosmos.Circuit.V1.AccountResponse)

  rpc(:Accounts, Cosmos.Circuit.V1.QueryAccountsRequest, Cosmos.Circuit.V1.AccountsResponse)

  rpc(
    :DisabledList,
    Cosmos.Circuit.V1.QueryDisabledListRequest,
    Cosmos.Circuit.V1.DisabledListResponse
  )
end

defmodule Cosmos.Circuit.V1.Query.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.Circuit.V1.Query.Service
end
