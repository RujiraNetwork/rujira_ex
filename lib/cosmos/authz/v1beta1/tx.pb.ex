defmodule Cosmos.Authz.V1beta1.MsgGrant do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:granter, 1, type: :string, deprecated: false)
  field(:grantee, 2, type: :string, deprecated: false)
  field(:grant, 3, type: Cosmos.Authz.V1beta1.Grant, deprecated: false)
end

defmodule Cosmos.Authz.V1beta1.MsgGrantResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Authz.V1beta1.MsgExec do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:grantee, 1, type: :string, deprecated: false)
  field(:msgs, 2, repeated: true, type: Google.Protobuf.Any, deprecated: false)
end

defmodule Cosmos.Authz.V1beta1.MsgExecResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:results, 1, repeated: true, type: :bytes)
end

defmodule Cosmos.Authz.V1beta1.MsgRevoke do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:granter, 1, type: :string, deprecated: false)
  field(:grantee, 2, type: :string, deprecated: false)
  field(:msg_type_url, 3, type: :string, json_name: "msgTypeUrl")
end

defmodule Cosmos.Authz.V1beta1.MsgRevokeResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Authz.V1beta1.Msg.Service do
  @moduledoc false

  use GRPC.Service, name: "cosmos.authz.v1beta1.Msg", protoc_gen_elixir_version: "0.13.0"

  rpc(:Grant, Cosmos.Authz.V1beta1.MsgGrant, Cosmos.Authz.V1beta1.MsgGrantResponse)

  rpc(:Exec, Cosmos.Authz.V1beta1.MsgExec, Cosmos.Authz.V1beta1.MsgExecResponse)

  rpc(:Revoke, Cosmos.Authz.V1beta1.MsgRevoke, Cosmos.Authz.V1beta1.MsgRevokeResponse)
end

defmodule Cosmos.Authz.V1beta1.Msg.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.Authz.V1beta1.Msg.Service
end
