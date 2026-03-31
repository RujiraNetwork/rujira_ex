defmodule Cosmos.Base.Reflection.V2alpha1.AppDescriptor do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:authn, 1, type: Cosmos.Base.Reflection.V2alpha1.AuthnDescriptor)
  field(:chain, 2, type: Cosmos.Base.Reflection.V2alpha1.ChainDescriptor)
  field(:codec, 3, type: Cosmos.Base.Reflection.V2alpha1.CodecDescriptor)
  field(:configuration, 4, type: Cosmos.Base.Reflection.V2alpha1.ConfigurationDescriptor)

  field(:query_services, 5,
    type: Cosmos.Base.Reflection.V2alpha1.QueryServicesDescriptor,
    json_name: "queryServices"
  )

  field(:tx, 6, type: Cosmos.Base.Reflection.V2alpha1.TxDescriptor)
end

defmodule Cosmos.Base.Reflection.V2alpha1.TxDescriptor do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:fullname, 1, type: :string)
  field(:msgs, 2, repeated: true, type: Cosmos.Base.Reflection.V2alpha1.MsgDescriptor)
end

defmodule Cosmos.Base.Reflection.V2alpha1.AuthnDescriptor do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:sign_modes, 1,
    repeated: true,
    type: Cosmos.Base.Reflection.V2alpha1.SigningModeDescriptor,
    json_name: "signModes"
  )
end

defmodule Cosmos.Base.Reflection.V2alpha1.SigningModeDescriptor do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:name, 1, type: :string)
  field(:number, 2, type: :int32)

  field(:authn_info_provider_method_fullname, 3,
    type: :string,
    json_name: "authnInfoProviderMethodFullname"
  )
end

defmodule Cosmos.Base.Reflection.V2alpha1.ChainDescriptor do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:id, 1, type: :string)
end

defmodule Cosmos.Base.Reflection.V2alpha1.CodecDescriptor do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:interfaces, 1, repeated: true, type: Cosmos.Base.Reflection.V2alpha1.InterfaceDescriptor)
end

defmodule Cosmos.Base.Reflection.V2alpha1.InterfaceDescriptor do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:fullname, 1, type: :string)

  field(:interface_accepting_messages, 2,
    repeated: true,
    type: Cosmos.Base.Reflection.V2alpha1.InterfaceAcceptingMessageDescriptor,
    json_name: "interfaceAcceptingMessages"
  )

  field(:interface_implementers, 3,
    repeated: true,
    type: Cosmos.Base.Reflection.V2alpha1.InterfaceImplementerDescriptor,
    json_name: "interfaceImplementers"
  )
end

defmodule Cosmos.Base.Reflection.V2alpha1.InterfaceImplementerDescriptor do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:fullname, 1, type: :string)
  field(:type_url, 2, type: :string, json_name: "typeUrl")
end

defmodule Cosmos.Base.Reflection.V2alpha1.InterfaceAcceptingMessageDescriptor do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:fullname, 1, type: :string)

  field(:field_descriptor_names, 2,
    repeated: true,
    type: :string,
    json_name: "fieldDescriptorNames"
  )
end

defmodule Cosmos.Base.Reflection.V2alpha1.ConfigurationDescriptor do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:bech32_account_address_prefix, 1, type: :string, json_name: "bech32AccountAddressPrefix")
end

defmodule Cosmos.Base.Reflection.V2alpha1.MsgDescriptor do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:msg_type_url, 1, type: :string, json_name: "msgTypeUrl")
end

defmodule Cosmos.Base.Reflection.V2alpha1.GetAuthnDescriptorRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Base.Reflection.V2alpha1.GetAuthnDescriptorResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:authn, 1, type: Cosmos.Base.Reflection.V2alpha1.AuthnDescriptor)
end

defmodule Cosmos.Base.Reflection.V2alpha1.GetChainDescriptorRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Base.Reflection.V2alpha1.GetChainDescriptorResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:chain, 1, type: Cosmos.Base.Reflection.V2alpha1.ChainDescriptor)
end

defmodule Cosmos.Base.Reflection.V2alpha1.GetCodecDescriptorRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Base.Reflection.V2alpha1.GetCodecDescriptorResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:codec, 1, type: Cosmos.Base.Reflection.V2alpha1.CodecDescriptor)
end

defmodule Cosmos.Base.Reflection.V2alpha1.GetConfigurationDescriptorRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Base.Reflection.V2alpha1.GetConfigurationDescriptorResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:config, 1, type: Cosmos.Base.Reflection.V2alpha1.ConfigurationDescriptor)
end

defmodule Cosmos.Base.Reflection.V2alpha1.GetQueryServicesDescriptorRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Base.Reflection.V2alpha1.GetQueryServicesDescriptorResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:queries, 1, type: Cosmos.Base.Reflection.V2alpha1.QueryServicesDescriptor)
end

defmodule Cosmos.Base.Reflection.V2alpha1.GetTxDescriptorRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Base.Reflection.V2alpha1.GetTxDescriptorResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx, 1, type: Cosmos.Base.Reflection.V2alpha1.TxDescriptor)
end

defmodule Cosmos.Base.Reflection.V2alpha1.QueryServicesDescriptor do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:query_services, 1,
    repeated: true,
    type: Cosmos.Base.Reflection.V2alpha1.QueryServiceDescriptor,
    json_name: "queryServices"
  )
end

defmodule Cosmos.Base.Reflection.V2alpha1.QueryServiceDescriptor do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:fullname, 1, type: :string)
  field(:is_module, 2, type: :bool, json_name: "isModule")
  field(:methods, 3, repeated: true, type: Cosmos.Base.Reflection.V2alpha1.QueryMethodDescriptor)
end

defmodule Cosmos.Base.Reflection.V2alpha1.QueryMethodDescriptor do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:name, 1, type: :string)
  field(:full_query_path, 2, type: :string, json_name: "fullQueryPath")
end

defmodule Cosmos.Base.Reflection.V2alpha1.ReflectionService.Service do
  @moduledoc false

  use GRPC.Service,
    name: "cosmos.base.reflection.v2alpha1.ReflectionService",
    protoc_gen_elixir_version: "0.13.0"

  rpc(
    :GetAuthnDescriptor,
    Cosmos.Base.Reflection.V2alpha1.GetAuthnDescriptorRequest,
    Cosmos.Base.Reflection.V2alpha1.GetAuthnDescriptorResponse
  )

  rpc(
    :GetChainDescriptor,
    Cosmos.Base.Reflection.V2alpha1.GetChainDescriptorRequest,
    Cosmos.Base.Reflection.V2alpha1.GetChainDescriptorResponse
  )

  rpc(
    :GetCodecDescriptor,
    Cosmos.Base.Reflection.V2alpha1.GetCodecDescriptorRequest,
    Cosmos.Base.Reflection.V2alpha1.GetCodecDescriptorResponse
  )

  rpc(
    :GetConfigurationDescriptor,
    Cosmos.Base.Reflection.V2alpha1.GetConfigurationDescriptorRequest,
    Cosmos.Base.Reflection.V2alpha1.GetConfigurationDescriptorResponse
  )

  rpc(
    :GetQueryServicesDescriptor,
    Cosmos.Base.Reflection.V2alpha1.GetQueryServicesDescriptorRequest,
    Cosmos.Base.Reflection.V2alpha1.GetQueryServicesDescriptorResponse
  )

  rpc(
    :GetTxDescriptor,
    Cosmos.Base.Reflection.V2alpha1.GetTxDescriptorRequest,
    Cosmos.Base.Reflection.V2alpha1.GetTxDescriptorResponse
  )
end

defmodule Cosmos.Base.Reflection.V2alpha1.ReflectionService.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.Base.Reflection.V2alpha1.ReflectionService.Service
end
