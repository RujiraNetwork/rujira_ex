defmodule Thorchain.Types.QueryOraclePriceRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
  field(:symbol, 2, type: :string)
end

defmodule Thorchain.Types.QueryOraclePriceResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:price, 1, type: Thorchain.Types.OraclePrice)
end

defmodule Thorchain.Types.OraclePrice do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:symbol, 1, type: :string)
  field(:price, 2, type: :string)
end
