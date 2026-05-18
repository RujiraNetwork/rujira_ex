defmodule Thorchain.Types.MsgTCYStake do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:signer, 1, type: :bytes, deprecated: false)
  field(:tx, 2, type: Thorchain.Common.Tx, deprecated: false)
end
