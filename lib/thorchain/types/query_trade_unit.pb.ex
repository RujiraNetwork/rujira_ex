defmodule Thorchain.Types.QueryTradeUnitRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asset, 1, type: :string)
  field(:height, 2, type: :string)
end

defmodule Thorchain.Types.QueryTradeUnitResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asset, 1, type: :string, deprecated: false)
  field(:units, 2, type: :string, deprecated: false)
  field(:depth, 3, type: :string, deprecated: false)
end

defmodule Thorchain.Types.QueryTradeUnitsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
end

defmodule Thorchain.Types.QueryTradeUnitsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:trade_units, 1,
    repeated: true,
    type: Thorchain.Types.QueryTradeUnitResponse,
    json_name: "tradeUnits"
  )
end
