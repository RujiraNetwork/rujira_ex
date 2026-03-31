defmodule Thorchain.Types.MsgReserveContributor do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx, 1, type: Thorchain.Common.Tx, deprecated: false)
  field(:contributor, 2, type: Thorchain.Types.ReserveContributor, deprecated: false)
  field(:signer, 3, type: :bytes, deprecated: false)
end
