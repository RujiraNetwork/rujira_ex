defmodule Cosmos.Auth.Module.V1.Module do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:bech32_prefix, 1, type: :string, json_name: "bech32Prefix")

  field(:module_account_permissions, 2,
    repeated: true,
    type: Cosmos.Auth.Module.V1.ModuleAccountPermission,
    json_name: "moduleAccountPermissions"
  )

  field(:authority, 3, type: :string)
end

defmodule Cosmos.Auth.Module.V1.ModuleAccountPermission do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:account, 1, type: :string)
  field(:permissions, 2, repeated: true, type: :string)
end
