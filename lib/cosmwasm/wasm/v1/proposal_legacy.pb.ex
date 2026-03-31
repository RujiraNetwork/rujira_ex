defmodule Cosmwasm.Wasm.V1.StoreCodeProposal do
  @moduledoc false

  use Protobuf, deprecated: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:title, 1, type: :string)
  field(:description, 2, type: :string)
  field(:run_as, 3, type: :string, json_name: "runAs", deprecated: false)
  field(:wasm_byte_code, 4, type: :bytes, json_name: "wasmByteCode", deprecated: false)

  field(:instantiate_permission, 7,
    type: Cosmwasm.Wasm.V1.AccessConfig,
    json_name: "instantiatePermission"
  )

  field(:unpin_code, 8, type: :bool, json_name: "unpinCode")
  field(:source, 9, type: :string)
  field(:builder, 10, type: :string)
  field(:code_hash, 11, type: :bytes, json_name: "codeHash")
end

defmodule Cosmwasm.Wasm.V1.InstantiateContractProposal do
  @moduledoc false

  use Protobuf, deprecated: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:title, 1, type: :string)
  field(:description, 2, type: :string)
  field(:run_as, 3, type: :string, json_name: "runAs", deprecated: false)
  field(:admin, 4, type: :string, deprecated: false)
  field(:code_id, 5, type: :uint64, json_name: "codeId", deprecated: false)
  field(:label, 6, type: :string)
  field(:msg, 7, type: :bytes, deprecated: false)
  field(:funds, 8, repeated: true, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
end

defmodule Cosmwasm.Wasm.V1.InstantiateContract2Proposal do
  @moduledoc false

  use Protobuf, deprecated: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:title, 1, type: :string)
  field(:description, 2, type: :string)
  field(:run_as, 3, type: :string, json_name: "runAs", deprecated: false)
  field(:admin, 4, type: :string, deprecated: false)
  field(:code_id, 5, type: :uint64, json_name: "codeId", deprecated: false)
  field(:label, 6, type: :string)
  field(:msg, 7, type: :bytes, deprecated: false)
  field(:funds, 8, repeated: true, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
  field(:salt, 9, type: :bytes)
  field(:fix_msg, 10, type: :bool, json_name: "fixMsg")
end

defmodule Cosmwasm.Wasm.V1.MigrateContractProposal do
  @moduledoc false

  use Protobuf, deprecated: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:title, 1, type: :string)
  field(:description, 2, type: :string)
  field(:contract, 4, type: :string, deprecated: false)
  field(:code_id, 5, type: :uint64, json_name: "codeId", deprecated: false)
  field(:msg, 6, type: :bytes, deprecated: false)
end

defmodule Cosmwasm.Wasm.V1.SudoContractProposal do
  @moduledoc false

  use Protobuf, deprecated: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:title, 1, type: :string)
  field(:description, 2, type: :string)
  field(:contract, 3, type: :string, deprecated: false)
  field(:msg, 4, type: :bytes, deprecated: false)
end

defmodule Cosmwasm.Wasm.V1.ExecuteContractProposal do
  @moduledoc false

  use Protobuf, deprecated: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:title, 1, type: :string)
  field(:description, 2, type: :string)
  field(:run_as, 3, type: :string, json_name: "runAs", deprecated: false)
  field(:contract, 4, type: :string, deprecated: false)
  field(:msg, 5, type: :bytes, deprecated: false)
  field(:funds, 6, repeated: true, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
end

defmodule Cosmwasm.Wasm.V1.UpdateAdminProposal do
  @moduledoc false

  use Protobuf, deprecated: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:title, 1, type: :string)
  field(:description, 2, type: :string)
  field(:new_admin, 3, type: :string, json_name: "newAdmin", deprecated: false)
  field(:contract, 4, type: :string, deprecated: false)
end

defmodule Cosmwasm.Wasm.V1.ClearAdminProposal do
  @moduledoc false

  use Protobuf, deprecated: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:title, 1, type: :string)
  field(:description, 2, type: :string)
  field(:contract, 3, type: :string, deprecated: false)
end

defmodule Cosmwasm.Wasm.V1.PinCodesProposal do
  @moduledoc false

  use Protobuf, deprecated: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:title, 1, type: :string)
  field(:description, 2, type: :string)
  field(:code_ids, 3, repeated: true, type: :uint64, json_name: "codeIds", deprecated: false)
end

defmodule Cosmwasm.Wasm.V1.UnpinCodesProposal do
  @moduledoc false

  use Protobuf, deprecated: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:title, 1, type: :string)
  field(:description, 2, type: :string)
  field(:code_ids, 3, repeated: true, type: :uint64, json_name: "codeIds", deprecated: false)
end

defmodule Cosmwasm.Wasm.V1.AccessConfigUpdate do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:code_id, 1, type: :uint64, json_name: "codeId", deprecated: false)

  field(:instantiate_permission, 2,
    type: Cosmwasm.Wasm.V1.AccessConfig,
    json_name: "instantiatePermission",
    deprecated: false
  )
end

defmodule Cosmwasm.Wasm.V1.UpdateInstantiateConfigProposal do
  @moduledoc false

  use Protobuf, deprecated: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:title, 1, type: :string, deprecated: false)
  field(:description, 2, type: :string, deprecated: false)

  field(:access_config_updates, 3,
    repeated: true,
    type: Cosmwasm.Wasm.V1.AccessConfigUpdate,
    json_name: "accessConfigUpdates",
    deprecated: false
  )
end

defmodule Cosmwasm.Wasm.V1.StoreAndInstantiateContractProposal do
  @moduledoc false

  use Protobuf, deprecated: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:title, 1, type: :string)
  field(:description, 2, type: :string)
  field(:run_as, 3, type: :string, json_name: "runAs", deprecated: false)
  field(:wasm_byte_code, 4, type: :bytes, json_name: "wasmByteCode", deprecated: false)

  field(:instantiate_permission, 5,
    type: Cosmwasm.Wasm.V1.AccessConfig,
    json_name: "instantiatePermission"
  )

  field(:unpin_code, 6, type: :bool, json_name: "unpinCode")
  field(:admin, 7, type: :string)
  field(:label, 8, type: :string)
  field(:msg, 9, type: :bytes, deprecated: false)
  field(:funds, 10, repeated: true, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
  field(:source, 11, type: :string)
  field(:builder, 12, type: :string)
  field(:code_hash, 13, type: :bytes, json_name: "codeHash")
end
