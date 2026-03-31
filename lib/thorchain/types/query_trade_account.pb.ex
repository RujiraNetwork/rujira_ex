defmodule Thorchain.Types.QueryTradeAccountRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string)
  field(:height, 2, type: :string)
end

defmodule Thorchain.Types.QueryTradeAccountResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asset, 1, type: :string, deprecated: false)
  field(:units, 2, type: :string, deprecated: false)
  field(:owner, 3, type: :string, deprecated: false)
  field(:last_add_height, 4, type: :int64, json_name: "lastAddHeight", deprecated: false)

  field(:last_withdraw_height, 5,
    type: :int64,
    json_name: "lastWithdrawHeight",
    deprecated: false
  )
end

defmodule Thorchain.Types.QueryTradeAccountsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asset, 1, type: :string)
  field(:height, 2, type: :string)
end

defmodule Thorchain.Types.QueryTradeAccountsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:trade_accounts, 1,
    repeated: true,
    type: Thorchain.Types.QueryTradeAccountResponse,
    json_name: "tradeAccounts"
  )
end
