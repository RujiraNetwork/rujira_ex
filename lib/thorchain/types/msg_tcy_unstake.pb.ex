defmodule Thorchain.Types.MsgTCYUnstake do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:signer, 1, type: :bytes, deprecated: false)
  field(:tx, 2, type: Thorchain.Common.Tx, deprecated: false)
  field(:basis_points, 3, type: :string, json_name: "basisPoints", deprecated: false)
end
