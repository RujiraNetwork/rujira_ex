defmodule Cosmos.Store.Internal.Kv.V1beta1.Pairs do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pairs, 1, repeated: true, type: Cosmos.Store.Internal.Kv.V1beta1.Pair, deprecated: false)
end

defmodule Cosmos.Store.Internal.Kv.V1beta1.Pair do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:key, 1, type: :bytes)
  field(:value, 2, type: :bytes)
end
