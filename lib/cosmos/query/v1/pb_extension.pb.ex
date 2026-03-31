defmodule Cosmos.Query.V1.PbExtension do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.13.0"

  extend(Google.Protobuf.MethodOptions, :module_query_safe, 11_110_001,
    optional: true,
    type: :bool,
    json_name: "moduleQuerySafe"
  )
end
