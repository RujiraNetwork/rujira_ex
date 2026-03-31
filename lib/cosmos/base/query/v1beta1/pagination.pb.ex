defmodule Cosmos.Base.Query.V1beta1.PageRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:key, 1, type: :bytes)
  field(:offset, 2, type: :uint64)
  field(:limit, 3, type: :uint64)
  field(:count_total, 4, type: :bool, json_name: "countTotal")
  field(:reverse, 5, type: :bool)
end

defmodule Cosmos.Base.Query.V1beta1.PageResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:next_key, 1, type: :bytes, json_name: "nextKey")
  field(:total, 2, type: :uint64)
end
