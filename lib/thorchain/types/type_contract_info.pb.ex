defmodule Thorchain.Types.ContractInfo do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string)
  field(:contract, 2, type: :string)
  field(:version, 3, type: :string)
end
