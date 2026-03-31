defmodule Cosmos.Circuit.V1.Permissions.Level do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:LEVEL_NONE_UNSPECIFIED, 0)
  field(:LEVEL_SOME_MSGS, 1)
  field(:LEVEL_ALL_MSGS, 2)
  field(:LEVEL_SUPER_ADMIN, 3)
end

defmodule Cosmos.Circuit.V1.Permissions do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:level, 1, type: Cosmos.Circuit.V1.Permissions.Level, enum: true)
  field(:limit_type_urls, 2, repeated: true, type: :string, json_name: "limitTypeUrls")
end

defmodule Cosmos.Circuit.V1.GenesisAccountPermissions do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string)
  field(:permissions, 2, type: Cosmos.Circuit.V1.Permissions)
end

defmodule Cosmos.Circuit.V1.GenesisState do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:account_permissions, 1,
    repeated: true,
    type: Cosmos.Circuit.V1.GenesisAccountPermissions,
    json_name: "accountPermissions"
  )

  field(:disabled_type_urls, 2, repeated: true, type: :string, json_name: "disabledTypeUrls")
end
