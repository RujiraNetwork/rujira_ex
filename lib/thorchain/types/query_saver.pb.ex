defmodule Thorchain.Types.QuerySaverRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asset, 1, type: :string)
  field(:address, 2, type: :string)
  field(:height, 3, type: :string)
end

defmodule Thorchain.Types.QuerySaverResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asset, 1, type: :string, deprecated: false)
  field(:asset_address, 2, type: :string, json_name: "assetAddress", deprecated: false)
  field(:last_add_height, 3, type: :int64, json_name: "lastAddHeight")
  field(:last_withdraw_height, 4, type: :int64, json_name: "lastWithdrawHeight")
  field(:units, 5, type: :string, deprecated: false)
  field(:asset_deposit_value, 6, type: :string, json_name: "assetDepositValue", deprecated: false)
  field(:asset_redeem_value, 7, type: :string, json_name: "assetRedeemValue", deprecated: false)
  field(:growth_pct, 8, type: :string, json_name: "growthPct", deprecated: false)
end

defmodule Thorchain.Types.QuerySaversRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asset, 1, type: :string)
  field(:height, 2, type: :string)
end

defmodule Thorchain.Types.QuerySaversResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:savers, 1, repeated: true, type: Thorchain.Types.QuerySaverResponse)
end
