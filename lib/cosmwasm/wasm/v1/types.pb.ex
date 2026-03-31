defmodule Cosmwasm.Wasm.V1.AccessType do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:ACCESS_TYPE_UNSPECIFIED, 0)
  field(:ACCESS_TYPE_NOBODY, 1)
  field(:ACCESS_TYPE_EVERYBODY, 3)
  field(:ACCESS_TYPE_ANY_OF_ADDRESSES, 4)
end

defmodule Cosmwasm.Wasm.V1.ContractCodeHistoryOperationType do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:CONTRACT_CODE_HISTORY_OPERATION_TYPE_UNSPECIFIED, 0)
  field(:CONTRACT_CODE_HISTORY_OPERATION_TYPE_INIT, 1)
  field(:CONTRACT_CODE_HISTORY_OPERATION_TYPE_MIGRATE, 2)
  field(:CONTRACT_CODE_HISTORY_OPERATION_TYPE_GENESIS, 3)
end

defmodule Cosmwasm.Wasm.V1.AccessTypeParam do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:value, 1, type: Cosmwasm.Wasm.V1.AccessType, enum: true, deprecated: false)
end

defmodule Cosmwasm.Wasm.V1.AccessConfig do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:permission, 1, type: Cosmwasm.Wasm.V1.AccessType, enum: true, deprecated: false)
  field(:addresses, 3, repeated: true, type: :string, deprecated: false)
end

defmodule Cosmwasm.Wasm.V1.Params do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:code_upload_access, 1,
    type: Cosmwasm.Wasm.V1.AccessConfig,
    json_name: "codeUploadAccess",
    deprecated: false
  )

  field(:instantiate_default_permission, 2,
    type: Cosmwasm.Wasm.V1.AccessType,
    json_name: "instantiateDefaultPermission",
    enum: true,
    deprecated: false
  )
end

defmodule Cosmwasm.Wasm.V1.CodeInfo do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:code_hash, 1, type: :bytes, json_name: "codeHash")
  field(:creator, 2, type: :string, deprecated: false)

  field(:instantiate_config, 5,
    type: Cosmwasm.Wasm.V1.AccessConfig,
    json_name: "instantiateConfig",
    deprecated: false
  )
end

defmodule Cosmwasm.Wasm.V1.ContractInfo do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:code_id, 1, type: :uint64, json_name: "codeId", deprecated: false)
  field(:creator, 2, type: :string, deprecated: false)
  field(:admin, 3, type: :string, deprecated: false)
  field(:label, 4, type: :string)
  field(:created, 5, type: Cosmwasm.Wasm.V1.AbsoluteTxPosition)
  field(:ibc_port_id, 6, type: :string, json_name: "ibcPortId", deprecated: false)
  field(:extension, 7, type: Google.Protobuf.Any, deprecated: false)
end

defmodule Cosmwasm.Wasm.V1.ContractCodeHistoryEntry do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:operation, 1, type: Cosmwasm.Wasm.V1.ContractCodeHistoryOperationType, enum: true)
  field(:code_id, 2, type: :uint64, json_name: "codeId", deprecated: false)
  field(:updated, 3, type: Cosmwasm.Wasm.V1.AbsoluteTxPosition)
  field(:msg, 4, type: :bytes, deprecated: false)
end

defmodule Cosmwasm.Wasm.V1.AbsoluteTxPosition do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:block_height, 1, type: :uint64, json_name: "blockHeight")
  field(:tx_index, 2, type: :uint64, json_name: "txIndex")
end

defmodule Cosmwasm.Wasm.V1.Model do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:key, 1, type: :bytes, deprecated: false)
  field(:value, 2, type: :bytes)
end
