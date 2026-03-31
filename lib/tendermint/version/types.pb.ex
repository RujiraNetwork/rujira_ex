defmodule Tendermint.Version.App do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:protocol, 1, type: :uint64)
  field(:software, 2, type: :string)
end

defmodule Tendermint.Version.Consensus do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:block, 1, type: :uint64)
  field(:app, 2, type: :uint64)
end
