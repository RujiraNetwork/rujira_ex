defmodule Thorchain.Thorchain.Denom.V1.GenesisState do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:admins, 1,
    repeated: true,
    type: Thorchain.Thorchain.Denom.V1.GenesisDenom,
    deprecated: false
  )
end

defmodule Thorchain.Thorchain.Denom.V1.GenesisDenom do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:denom, 1, type: :string, deprecated: false)
  field(:admin, 2, type: :string, deprecated: false)
end
