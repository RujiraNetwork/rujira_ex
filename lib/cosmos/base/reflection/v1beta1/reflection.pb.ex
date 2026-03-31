defmodule Cosmos.Base.Reflection.V1beta1.ListAllInterfacesRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Base.Reflection.V1beta1.ListAllInterfacesResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:interface_names, 1, repeated: true, type: :string, json_name: "interfaceNames")
end

defmodule Cosmos.Base.Reflection.V1beta1.ListImplementationsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:interface_name, 1, type: :string, json_name: "interfaceName")
end

defmodule Cosmos.Base.Reflection.V1beta1.ListImplementationsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:implementation_message_names, 1,
    repeated: true,
    type: :string,
    json_name: "implementationMessageNames"
  )
end

defmodule Cosmos.Base.Reflection.V1beta1.ReflectionService.Service do
  @moduledoc false

  use GRPC.Service,
    name: "cosmos.base.reflection.v1beta1.ReflectionService",
    protoc_gen_elixir_version: "0.13.0"

  rpc(
    :ListAllInterfaces,
    Cosmos.Base.Reflection.V1beta1.ListAllInterfacesRequest,
    Cosmos.Base.Reflection.V1beta1.ListAllInterfacesResponse
  )

  rpc(
    :ListImplementations,
    Cosmos.Base.Reflection.V1beta1.ListImplementationsRequest,
    Cosmos.Base.Reflection.V1beta1.ListImplementationsResponse
  )
end

defmodule Cosmos.Base.Reflection.V1beta1.ReflectionService.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.Base.Reflection.V1beta1.ReflectionService.Service
end
