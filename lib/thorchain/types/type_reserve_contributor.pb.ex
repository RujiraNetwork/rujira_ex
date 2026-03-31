defmodule Thorchain.Types.ReserveContributor do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)
  field(:amount, 2, type: :string, deprecated: false)
end
