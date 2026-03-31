defmodule Cosmos.App.V1alpha1.Config do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:modules, 1, repeated: true, type: Cosmos.App.V1alpha1.ModuleConfig)

  field(:golang_bindings, 2,
    repeated: true,
    type: Cosmos.App.V1alpha1.GolangBinding,
    json_name: "golangBindings"
  )
end

defmodule Cosmos.App.V1alpha1.ModuleConfig do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:name, 1, type: :string)
  field(:config, 2, type: Google.Protobuf.Any)

  field(:golang_bindings, 3,
    repeated: true,
    type: Cosmos.App.V1alpha1.GolangBinding,
    json_name: "golangBindings"
  )
end

defmodule Cosmos.App.V1alpha1.GolangBinding do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:interface_type, 1, type: :string, json_name: "interfaceType")
  field(:implementation, 2, type: :string)
end
