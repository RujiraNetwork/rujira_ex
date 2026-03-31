defmodule Cosmos.Orm.V1alpha1.StorageType do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:STORAGE_TYPE_DEFAULT_UNSPECIFIED, 0)
  field(:STORAGE_TYPE_MEMORY, 1)
  field(:STORAGE_TYPE_TRANSIENT, 2)
end

defmodule Cosmos.Orm.V1alpha1.ModuleSchemaDescriptor.FileEntry do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:id, 1, type: :uint32)
  field(:proto_file_name, 2, type: :string, json_name: "protoFileName")

  field(:storage_type, 3,
    type: Cosmos.Orm.V1alpha1.StorageType,
    json_name: "storageType",
    enum: true
  )
end

defmodule Cosmos.Orm.V1alpha1.ModuleSchemaDescriptor do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:schema_file, 1,
    repeated: true,
    type: Cosmos.Orm.V1alpha1.ModuleSchemaDescriptor.FileEntry,
    json_name: "schemaFile"
  )

  field(:prefix, 2, type: :bytes)
end
