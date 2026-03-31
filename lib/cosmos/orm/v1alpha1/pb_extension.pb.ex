defmodule Cosmos.Orm.V1alpha1.PbExtension do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.13.0"

  extend(Google.Protobuf.MessageOptions, :module_schema, 104_503_792,
    optional: true,
    type: Cosmos.Orm.V1alpha1.ModuleSchemaDescriptor,
    json_name: "moduleSchema"
  )
end
