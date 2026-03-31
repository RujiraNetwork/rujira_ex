defmodule Cosmos.Bank.V1beta1.GenesisState do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:params, 1, type: Cosmos.Bank.V1beta1.Params, deprecated: false)
  field(:balances, 2, repeated: true, type: Cosmos.Bank.V1beta1.Balance, deprecated: false)
  field(:supply, 3, repeated: true, type: Cosmos.Base.V1beta1.Coin, deprecated: false)

  field(:denom_metadata, 4,
    repeated: true,
    type: Cosmos.Bank.V1beta1.Metadata,
    json_name: "denomMetadata",
    deprecated: false
  )

  field(:send_enabled, 5,
    repeated: true,
    type: Cosmos.Bank.V1beta1.SendEnabled,
    json_name: "sendEnabled",
    deprecated: false
  )
end

defmodule Cosmos.Bank.V1beta1.Balance do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)
  field(:coins, 2, repeated: true, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
end
