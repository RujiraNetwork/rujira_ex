defmodule Thorchain.Types.SwapperClout do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)
  field(:score, 2, type: :string, deprecated: false)
  field(:reclaimed, 3, type: :string, deprecated: false)
  field(:spent, 4, type: :string, deprecated: false)
  field(:last_spent_height, 5, type: :int64, json_name: "lastSpentHeight")
  field(:last_reclaim_height, 6, type: :int64, json_name: "lastReclaimHeight")
end
