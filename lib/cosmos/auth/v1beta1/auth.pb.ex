defmodule Cosmos.Auth.V1beta1.BaseAccount do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)
  field(:pub_key, 2, type: Google.Protobuf.Any, json_name: "pubKey", deprecated: false)
  field(:account_number, 3, type: :uint64, json_name: "accountNumber")
  field(:sequence, 4, type: :uint64)
end

defmodule Cosmos.Auth.V1beta1.ModuleAccount do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:base_account, 1,
    type: Cosmos.Auth.V1beta1.BaseAccount,
    json_name: "baseAccount",
    deprecated: false
  )

  field(:name, 2, type: :string)
  field(:permissions, 3, repeated: true, type: :string)
end

defmodule Cosmos.Auth.V1beta1.ModuleCredential do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:module_name, 1, type: :string, json_name: "moduleName")
  field(:derivation_keys, 2, repeated: true, type: :bytes, json_name: "derivationKeys")
end

defmodule Cosmos.Auth.V1beta1.Params do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:max_memo_characters, 1, type: :uint64, json_name: "maxMemoCharacters")
  field(:tx_sig_limit, 2, type: :uint64, json_name: "txSigLimit")
  field(:tx_size_cost_per_byte, 3, type: :uint64, json_name: "txSizeCostPerByte")

  field(:sig_verify_cost_ed25519, 4,
    type: :uint64,
    json_name: "sigVerifyCostEd25519",
    deprecated: false
  )

  field(:sig_verify_cost_secp256k1, 5,
    type: :uint64,
    json_name: "sigVerifyCostSecp256k1",
    deprecated: false
  )
end
