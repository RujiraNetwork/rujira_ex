defmodule Thorchain.Types.QueryBalancesRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string)
  field(:height, 2, type: :string)
end

defmodule Thorchain.Types.QueryBalancesResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:balances, 1, repeated: true, type: Thorchain.Types.Amount)
end

defmodule Thorchain.Types.Amount do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:denom, 1, type: :string)
  field(:amount, 2, type: :string)
end
