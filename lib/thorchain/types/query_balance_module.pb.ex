defmodule Thorchain.Types.QueryBalanceModuleRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:name, 1, type: :string)
  field(:height, 2, type: :string)
end

defmodule Thorchain.Types.QueryBalanceModuleResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:name, 1, type: :string, deprecated: false)
  field(:address, 2, type: :bytes, deprecated: false)
  field(:coins, 3, repeated: true, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
end
