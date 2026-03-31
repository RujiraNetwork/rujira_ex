defmodule Cosmwasm.Wasm.V1.GenesisState do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:params, 1, type: Cosmwasm.Wasm.V1.Params, deprecated: false)
  field(:codes, 2, repeated: true, type: Cosmwasm.Wasm.V1.Code, deprecated: false)
  field(:contracts, 3, repeated: true, type: Cosmwasm.Wasm.V1.Contract, deprecated: false)
  field(:sequences, 4, repeated: true, type: Cosmwasm.Wasm.V1.Sequence, deprecated: false)
end

defmodule Cosmwasm.Wasm.V1.Code do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:code_id, 1, type: :uint64, json_name: "codeId", deprecated: false)
  field(:code_info, 2, type: Cosmwasm.Wasm.V1.CodeInfo, json_name: "codeInfo", deprecated: false)
  field(:code_bytes, 3, type: :bytes, json_name: "codeBytes")
  field(:pinned, 4, type: :bool)
end

defmodule Cosmwasm.Wasm.V1.Contract do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:contract_address, 1, type: :string, json_name: "contractAddress", deprecated: false)

  field(:contract_info, 2,
    type: Cosmwasm.Wasm.V1.ContractInfo,
    json_name: "contractInfo",
    deprecated: false
  )

  field(:contract_state, 3,
    repeated: true,
    type: Cosmwasm.Wasm.V1.Model,
    json_name: "contractState",
    deprecated: false
  )

  field(:contract_code_history, 4,
    repeated: true,
    type: Cosmwasm.Wasm.V1.ContractCodeHistoryEntry,
    json_name: "contractCodeHistory",
    deprecated: false
  )
end

defmodule Cosmwasm.Wasm.V1.Sequence do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:id_key, 1, type: :bytes, json_name: "idKey", deprecated: false)
  field(:value, 2, type: :uint64)
end
