defmodule Cosmos.App.V1alpha1.ModuleDescriptor do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:go_import, 1, type: :string, json_name: "goImport")

  field(:use_package, 2,
    repeated: true,
    type: Cosmos.App.V1alpha1.PackageReference,
    json_name: "usePackage"
  )

  field(:can_migrate_from, 3,
    repeated: true,
    type: Cosmos.App.V1alpha1.MigrateFromInfo,
    json_name: "canMigrateFrom"
  )
end

defmodule Cosmos.App.V1alpha1.PackageReference do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:name, 1, type: :string)
  field(:revision, 2, type: :uint32)
end

defmodule Cosmos.App.V1alpha1.MigrateFromInfo do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:module, 1, type: :string)
end
