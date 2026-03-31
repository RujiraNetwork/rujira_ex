defmodule Thorchain.Types.TradeAccount do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asset, 1, type: Thorchain.Common.Asset, deprecated: false)
  field(:units, 2, type: :string, deprecated: false)
  field(:owner, 3, type: :bytes, deprecated: false)
  field(:last_add_height, 4, type: :int64, json_name: "lastAddHeight")
  field(:last_withdraw_height, 5, type: :int64, json_name: "lastWithdrawHeight")
end

defmodule Thorchain.Types.TradeUnit do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asset, 1, type: Thorchain.Common.Asset, deprecated: false)
  field(:units, 2, type: :string, deprecated: false)
  field(:depth, 3, type: :string, deprecated: false)
end
