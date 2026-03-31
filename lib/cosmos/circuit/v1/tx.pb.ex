defmodule Cosmos.Circuit.V1.MsgAuthorizeCircuitBreaker do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:granter, 1, type: :string)
  field(:grantee, 2, type: :string)
  field(:permissions, 3, type: Cosmos.Circuit.V1.Permissions)
end

defmodule Cosmos.Circuit.V1.MsgAuthorizeCircuitBreakerResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:success, 1, type: :bool)
end

defmodule Cosmos.Circuit.V1.MsgTripCircuitBreaker do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:authority, 1, type: :string)
  field(:msg_type_urls, 2, repeated: true, type: :string, json_name: "msgTypeUrls")
end

defmodule Cosmos.Circuit.V1.MsgTripCircuitBreakerResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:success, 1, type: :bool)
end

defmodule Cosmos.Circuit.V1.MsgResetCircuitBreaker do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:authority, 1, type: :string)
  field(:msg_type_urls, 3, repeated: true, type: :string, json_name: "msgTypeUrls")
end

defmodule Cosmos.Circuit.V1.MsgResetCircuitBreakerResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:success, 1, type: :bool)
end

defmodule Cosmos.Circuit.V1.Msg.Service do
  @moduledoc false

  use GRPC.Service, name: "cosmos.circuit.v1.Msg", protoc_gen_elixir_version: "0.13.0"

  rpc(
    :AuthorizeCircuitBreaker,
    Cosmos.Circuit.V1.MsgAuthorizeCircuitBreaker,
    Cosmos.Circuit.V1.MsgAuthorizeCircuitBreakerResponse
  )

  rpc(
    :TripCircuitBreaker,
    Cosmos.Circuit.V1.MsgTripCircuitBreaker,
    Cosmos.Circuit.V1.MsgTripCircuitBreakerResponse
  )

  rpc(
    :ResetCircuitBreaker,
    Cosmos.Circuit.V1.MsgResetCircuitBreaker,
    Cosmos.Circuit.V1.MsgResetCircuitBreakerResponse
  )
end

defmodule Cosmos.Circuit.V1.Msg.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.Circuit.V1.Msg.Service
end
