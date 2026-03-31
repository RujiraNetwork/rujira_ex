defmodule Cosmos.Reflection.V1.FileDescriptorsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Reflection.V1.FileDescriptorsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:files, 1, repeated: true, type: Google.Protobuf.FileDescriptorProto)
end

defmodule Cosmos.Reflection.V1.ReflectionService.Service do
  @moduledoc false

  use GRPC.Service,
    name: "cosmos.reflection.v1.ReflectionService",
    protoc_gen_elixir_version: "0.13.0"

  rpc(
    :FileDescriptors,
    Cosmos.Reflection.V1.FileDescriptorsRequest,
    Cosmos.Reflection.V1.FileDescriptorsResponse
  )
end

defmodule Cosmos.Reflection.V1.ReflectionService.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.Reflection.V1.ReflectionService.Service
end
