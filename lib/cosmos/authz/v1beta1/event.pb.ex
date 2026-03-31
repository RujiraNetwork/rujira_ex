defmodule Cosmos.Authz.V1beta1.EventGrant do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:msg_type_url, 2, type: :string, json_name: "msgTypeUrl")
  field(:granter, 3, type: :string, deprecated: false)
  field(:grantee, 4, type: :string, deprecated: false)
end

defmodule Cosmos.Authz.V1beta1.EventRevoke do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:msg_type_url, 2, type: :string, json_name: "msgTypeUrl")
  field(:granter, 3, type: :string, deprecated: false)
  field(:grantee, 4, type: :string, deprecated: false)
end
