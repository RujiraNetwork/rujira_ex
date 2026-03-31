defmodule Thorchain.Types.KeygenType do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:UnknownKeygen, 0)
  field(:AsgardKeygen, 1)
end

defmodule Thorchain.Types.Keygen do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:id, 1, type: :string, deprecated: false)
  field(:type, 2, type: Thorchain.Types.KeygenType, enum: true)
  field(:members, 3, repeated: true, type: :string)
end

defmodule Thorchain.Types.KeygenBlock do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :int64)
  field(:keygens, 4, repeated: true, type: Thorchain.Types.Keygen, deprecated: false)
end
