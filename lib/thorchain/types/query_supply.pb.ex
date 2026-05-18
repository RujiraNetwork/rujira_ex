defmodule Thorchain.Types.LockedSupply do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:reserve, 1, type: :int64, deprecated: false)
end

defmodule Thorchain.Types.QuerySupplyRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
end

defmodule Thorchain.Types.QuerySupplyResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:circulating, 1, type: :int64, deprecated: false)
  field(:locked, 2, type: Thorchain.Types.LockedSupply, deprecated: false)
  field(:total, 3, type: :int64, deprecated: false)
end
