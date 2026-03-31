defmodule Cosmos.App.V1alpha1.PbExtension do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.13.0"

  extend(Google.Protobuf.MessageOptions, :module, 57_193_479,
    optional: true,
    type: Cosmos.App.V1alpha1.ModuleDescriptor
  )
end
