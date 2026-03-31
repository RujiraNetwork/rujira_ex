defmodule Thorchain.Types.QueryRuneProviderRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string)
  field(:height, 2, type: :string)
end

defmodule Thorchain.Types.QueryRuneProviderResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:rune_address, 1, type: :string, json_name: "runeAddress", deprecated: false)
  field(:units, 2, type: :string, deprecated: false)
  field(:value, 3, type: :string, deprecated: false)
  field(:pnl, 4, type: :string, deprecated: false)
  field(:deposit_amount, 5, type: :string, json_name: "depositAmount", deprecated: false)
  field(:withdraw_amount, 6, type: :string, json_name: "withdrawAmount", deprecated: false)
  field(:last_deposit_height, 7, type: :int64, json_name: "lastDepositHeight", deprecated: false)

  field(:last_withdraw_height, 8,
    type: :int64,
    json_name: "lastWithdrawHeight",
    deprecated: false
  )
end

defmodule Thorchain.Types.QueryRuneProvidersRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
end

defmodule Thorchain.Types.QueryRuneProvidersResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:providers, 1, repeated: true, type: Thorchain.Types.QueryRuneProviderResponse)
end
