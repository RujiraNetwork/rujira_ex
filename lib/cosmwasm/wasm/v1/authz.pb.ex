defmodule Cosmwasm.Wasm.V1.StoreCodeAuthorization do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:grants, 1, repeated: true, type: Cosmwasm.Wasm.V1.CodeGrant, deprecated: false)
end

defmodule Cosmwasm.Wasm.V1.ContractExecutionAuthorization do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:grants, 1, repeated: true, type: Cosmwasm.Wasm.V1.ContractGrant, deprecated: false)
end

defmodule Cosmwasm.Wasm.V1.ContractMigrationAuthorization do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:grants, 1, repeated: true, type: Cosmwasm.Wasm.V1.ContractGrant, deprecated: false)
end

defmodule Cosmwasm.Wasm.V1.CodeGrant do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:code_hash, 1, type: :bytes, json_name: "codeHash")

  field(:instantiate_permission, 2,
    type: Cosmwasm.Wasm.V1.AccessConfig,
    json_name: "instantiatePermission"
  )
end

defmodule Cosmwasm.Wasm.V1.ContractGrant do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:contract, 1, type: :string, deprecated: false)
  field(:limit, 2, type: Google.Protobuf.Any, deprecated: false)
  field(:filter, 3, type: Google.Protobuf.Any, deprecated: false)
end

defmodule Cosmwasm.Wasm.V1.MaxCallsLimit do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:remaining, 1, type: :uint64)
end

defmodule Cosmwasm.Wasm.V1.MaxFundsLimit do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:amounts, 1, repeated: true, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
end

defmodule Cosmwasm.Wasm.V1.CombinedLimit do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:calls_remaining, 1, type: :uint64, json_name: "callsRemaining")
  field(:amounts, 2, repeated: true, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
end

defmodule Cosmwasm.Wasm.V1.AllowAllMessagesFilter do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmwasm.Wasm.V1.AcceptedMessageKeysFilter do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:keys, 1, repeated: true, type: :string)
end

defmodule Cosmwasm.Wasm.V1.AcceptedMessagesFilter do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:messages, 1, repeated: true, type: :bytes, deprecated: false)
end
