defmodule Thorchain.Types.InjectTx do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:messages, 1, repeated: true, type: Google.Protobuf.Any)
end
