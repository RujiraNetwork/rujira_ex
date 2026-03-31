defmodule Cosmos.App.Runtime.V1alpha1.Module do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:app_name, 1, type: :string, json_name: "appName")
  field(:begin_blockers, 2, repeated: true, type: :string, json_name: "beginBlockers")
  field(:end_blockers, 3, repeated: true, type: :string, json_name: "endBlockers")
  field(:init_genesis, 4, repeated: true, type: :string, json_name: "initGenesis")
  field(:export_genesis, 5, repeated: true, type: :string, json_name: "exportGenesis")

  field(:override_store_keys, 6,
    repeated: true,
    type: Cosmos.App.Runtime.V1alpha1.StoreKeyConfig,
    json_name: "overrideStoreKeys"
  )

  field(:order_migrations, 7, repeated: true, type: :string, json_name: "orderMigrations")
  field(:precommiters, 8, repeated: true, type: :string)

  field(:prepare_check_staters, 9,
    repeated: true,
    type: :string,
    json_name: "prepareCheckStaters"
  )
end

defmodule Cosmos.App.Runtime.V1alpha1.StoreKeyConfig do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:module_name, 1, type: :string, json_name: "moduleName")
  field(:kv_store_key, 2, type: :string, json_name: "kvStoreKey")
end
