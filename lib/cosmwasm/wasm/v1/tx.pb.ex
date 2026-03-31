defmodule Cosmwasm.Wasm.V1.MsgStoreCode do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:sender, 1, type: :string, deprecated: false)
  field(:wasm_byte_code, 2, type: :bytes, json_name: "wasmByteCode", deprecated: false)

  field(:instantiate_permission, 5,
    type: Cosmwasm.Wasm.V1.AccessConfig,
    json_name: "instantiatePermission"
  )
end

defmodule Cosmwasm.Wasm.V1.MsgStoreCodeResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:code_id, 1, type: :uint64, json_name: "codeId", deprecated: false)
  field(:checksum, 2, type: :bytes)
end

defmodule Cosmwasm.Wasm.V1.MsgInstantiateContract do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:sender, 1, type: :string, deprecated: false)
  field(:admin, 2, type: :string, deprecated: false)
  field(:code_id, 3, type: :uint64, json_name: "codeId", deprecated: false)
  field(:label, 4, type: :string)
  field(:msg, 5, type: :bytes, deprecated: false)
  field(:funds, 6, repeated: true, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
end

defmodule Cosmwasm.Wasm.V1.MsgInstantiateContractResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)
  field(:data, 2, type: :bytes)
end

defmodule Cosmwasm.Wasm.V1.MsgInstantiateContract2 do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:sender, 1, type: :string, deprecated: false)
  field(:admin, 2, type: :string, deprecated: false)
  field(:code_id, 3, type: :uint64, json_name: "codeId", deprecated: false)
  field(:label, 4, type: :string)
  field(:msg, 5, type: :bytes, deprecated: false)
  field(:funds, 6, repeated: true, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
  field(:salt, 7, type: :bytes)
  field(:fix_msg, 8, type: :bool, json_name: "fixMsg")
end

defmodule Cosmwasm.Wasm.V1.MsgInstantiateContract2Response do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)
  field(:data, 2, type: :bytes)
end

defmodule Cosmwasm.Wasm.V1.MsgExecuteContract do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:sender, 1, type: :string, deprecated: false)
  field(:contract, 2, type: :string, deprecated: false)
  field(:msg, 3, type: :bytes, deprecated: false)
  field(:funds, 5, repeated: true, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
end

defmodule Cosmwasm.Wasm.V1.MsgExecuteContractResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:data, 1, type: :bytes)
end

defmodule Cosmwasm.Wasm.V1.MsgMigrateContract do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:sender, 1, type: :string, deprecated: false)
  field(:contract, 2, type: :string, deprecated: false)
  field(:code_id, 3, type: :uint64, json_name: "codeId", deprecated: false)
  field(:msg, 4, type: :bytes, deprecated: false)
end

defmodule Cosmwasm.Wasm.V1.MsgMigrateContractResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:data, 1, type: :bytes)
end

defmodule Cosmwasm.Wasm.V1.MsgUpdateAdmin do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:sender, 1, type: :string, deprecated: false)
  field(:new_admin, 2, type: :string, json_name: "newAdmin", deprecated: false)
  field(:contract, 3, type: :string, deprecated: false)
end

defmodule Cosmwasm.Wasm.V1.MsgUpdateAdminResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmwasm.Wasm.V1.MsgClearAdmin do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:sender, 1, type: :string, deprecated: false)
  field(:contract, 3, type: :string, deprecated: false)
end

defmodule Cosmwasm.Wasm.V1.MsgClearAdminResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmwasm.Wasm.V1.MsgUpdateInstantiateConfig do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:sender, 1, type: :string, deprecated: false)
  field(:code_id, 2, type: :uint64, json_name: "codeId", deprecated: false)

  field(:new_instantiate_permission, 3,
    type: Cosmwasm.Wasm.V1.AccessConfig,
    json_name: "newInstantiatePermission"
  )
end

defmodule Cosmwasm.Wasm.V1.MsgUpdateInstantiateConfigResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmwasm.Wasm.V1.MsgUpdateParams do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:authority, 1, type: :string, deprecated: false)
  field(:params, 2, type: Cosmwasm.Wasm.V1.Params, deprecated: false)
end

defmodule Cosmwasm.Wasm.V1.MsgUpdateParamsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmwasm.Wasm.V1.MsgSudoContract do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:authority, 1, type: :string, deprecated: false)
  field(:contract, 2, type: :string, deprecated: false)
  field(:msg, 3, type: :bytes, deprecated: false)
end

defmodule Cosmwasm.Wasm.V1.MsgSudoContractResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:data, 1, type: :bytes)
end

defmodule Cosmwasm.Wasm.V1.MsgPinCodes do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:authority, 1, type: :string, deprecated: false)
  field(:code_ids, 2, repeated: true, type: :uint64, json_name: "codeIds", deprecated: false)
end

defmodule Cosmwasm.Wasm.V1.MsgPinCodesResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmwasm.Wasm.V1.MsgUnpinCodes do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:authority, 1, type: :string, deprecated: false)
  field(:code_ids, 2, repeated: true, type: :uint64, json_name: "codeIds", deprecated: false)
end

defmodule Cosmwasm.Wasm.V1.MsgUnpinCodesResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmwasm.Wasm.V1.MsgStoreAndInstantiateContract do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:authority, 1, type: :string, deprecated: false)
  field(:wasm_byte_code, 3, type: :bytes, json_name: "wasmByteCode", deprecated: false)

  field(:instantiate_permission, 4,
    type: Cosmwasm.Wasm.V1.AccessConfig,
    json_name: "instantiatePermission"
  )

  field(:unpin_code, 5, type: :bool, json_name: "unpinCode")
  field(:admin, 6, type: :string, deprecated: false)
  field(:label, 7, type: :string)
  field(:msg, 8, type: :bytes, deprecated: false)
  field(:funds, 9, repeated: true, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
  field(:source, 10, type: :string)
  field(:builder, 11, type: :string)
  field(:code_hash, 12, type: :bytes, json_name: "codeHash")
end

defmodule Cosmwasm.Wasm.V1.MsgStoreAndInstantiateContractResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)
  field(:data, 2, type: :bytes)
end

defmodule Cosmwasm.Wasm.V1.MsgAddCodeUploadParamsAddresses do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:authority, 1, type: :string, deprecated: false)
  field(:addresses, 2, repeated: true, type: :string, deprecated: false)
end

defmodule Cosmwasm.Wasm.V1.MsgAddCodeUploadParamsAddressesResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmwasm.Wasm.V1.MsgRemoveCodeUploadParamsAddresses do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:authority, 1, type: :string, deprecated: false)
  field(:addresses, 2, repeated: true, type: :string, deprecated: false)
end

defmodule Cosmwasm.Wasm.V1.MsgRemoveCodeUploadParamsAddressesResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmwasm.Wasm.V1.MsgStoreAndMigrateContract do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:authority, 1, type: :string, deprecated: false)
  field(:wasm_byte_code, 2, type: :bytes, json_name: "wasmByteCode", deprecated: false)

  field(:instantiate_permission, 3,
    type: Cosmwasm.Wasm.V1.AccessConfig,
    json_name: "instantiatePermission"
  )

  field(:contract, 4, type: :string)
  field(:msg, 5, type: :bytes, deprecated: false)
end

defmodule Cosmwasm.Wasm.V1.MsgStoreAndMigrateContractResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:code_id, 1, type: :uint64, json_name: "codeId", deprecated: false)
  field(:checksum, 2, type: :bytes)
  field(:data, 3, type: :bytes)
end

defmodule Cosmwasm.Wasm.V1.MsgUpdateContractLabel do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:sender, 1, type: :string, deprecated: false)
  field(:new_label, 2, type: :string, json_name: "newLabel")
  field(:contract, 3, type: :string, deprecated: false)
end

defmodule Cosmwasm.Wasm.V1.MsgUpdateContractLabelResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmwasm.Wasm.V1.Msg.Service do
  @moduledoc false

  use GRPC.Service, name: "cosmwasm.wasm.v1.Msg", protoc_gen_elixir_version: "0.13.0"

  rpc(:StoreCode, Cosmwasm.Wasm.V1.MsgStoreCode, Cosmwasm.Wasm.V1.MsgStoreCodeResponse)

  rpc(
    :InstantiateContract,
    Cosmwasm.Wasm.V1.MsgInstantiateContract,
    Cosmwasm.Wasm.V1.MsgInstantiateContractResponse
  )

  rpc(
    :InstantiateContract2,
    Cosmwasm.Wasm.V1.MsgInstantiateContract2,
    Cosmwasm.Wasm.V1.MsgInstantiateContract2Response
  )

  rpc(
    :ExecuteContract,
    Cosmwasm.Wasm.V1.MsgExecuteContract,
    Cosmwasm.Wasm.V1.MsgExecuteContractResponse
  )

  rpc(
    :MigrateContract,
    Cosmwasm.Wasm.V1.MsgMigrateContract,
    Cosmwasm.Wasm.V1.MsgMigrateContractResponse
  )

  rpc(:UpdateAdmin, Cosmwasm.Wasm.V1.MsgUpdateAdmin, Cosmwasm.Wasm.V1.MsgUpdateAdminResponse)

  rpc(:ClearAdmin, Cosmwasm.Wasm.V1.MsgClearAdmin, Cosmwasm.Wasm.V1.MsgClearAdminResponse)

  rpc(
    :UpdateInstantiateConfig,
    Cosmwasm.Wasm.V1.MsgUpdateInstantiateConfig,
    Cosmwasm.Wasm.V1.MsgUpdateInstantiateConfigResponse
  )

  rpc(:UpdateParams, Cosmwasm.Wasm.V1.MsgUpdateParams, Cosmwasm.Wasm.V1.MsgUpdateParamsResponse)

  rpc(:SudoContract, Cosmwasm.Wasm.V1.MsgSudoContract, Cosmwasm.Wasm.V1.MsgSudoContractResponse)

  rpc(:PinCodes, Cosmwasm.Wasm.V1.MsgPinCodes, Cosmwasm.Wasm.V1.MsgPinCodesResponse)

  rpc(:UnpinCodes, Cosmwasm.Wasm.V1.MsgUnpinCodes, Cosmwasm.Wasm.V1.MsgUnpinCodesResponse)

  rpc(
    :StoreAndInstantiateContract,
    Cosmwasm.Wasm.V1.MsgStoreAndInstantiateContract,
    Cosmwasm.Wasm.V1.MsgStoreAndInstantiateContractResponse
  )

  rpc(
    :RemoveCodeUploadParamsAddresses,
    Cosmwasm.Wasm.V1.MsgRemoveCodeUploadParamsAddresses,
    Cosmwasm.Wasm.V1.MsgRemoveCodeUploadParamsAddressesResponse
  )

  rpc(
    :AddCodeUploadParamsAddresses,
    Cosmwasm.Wasm.V1.MsgAddCodeUploadParamsAddresses,
    Cosmwasm.Wasm.V1.MsgAddCodeUploadParamsAddressesResponse
  )

  rpc(
    :StoreAndMigrateContract,
    Cosmwasm.Wasm.V1.MsgStoreAndMigrateContract,
    Cosmwasm.Wasm.V1.MsgStoreAndMigrateContractResponse
  )

  rpc(
    :UpdateContractLabel,
    Cosmwasm.Wasm.V1.MsgUpdateContractLabel,
    Cosmwasm.Wasm.V1.MsgUpdateContractLabelResponse
  )
end

defmodule Cosmwasm.Wasm.V1.Msg.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmwasm.Wasm.V1.Msg.Service
end
