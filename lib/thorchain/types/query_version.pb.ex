defmodule Thorchain.Types.QueryVersionRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
end

defmodule Thorchain.Types.QueryVersionResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:current, 1, type: :string, deprecated: false)
  field(:next, 2, type: :string, deprecated: false)
  field(:next_since_height, 3, type: :int64, json_name: "nextSinceHeight")
  field(:querier, 4, type: :string, deprecated: false)
end
