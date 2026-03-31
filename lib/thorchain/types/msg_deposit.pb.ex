defmodule Thorchain.Types.MsgDeposit do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:coins, 1, repeated: true, type: Thorchain.Common.Coin, deprecated: false)
  field(:memo, 2, type: :string)
  field(:signer, 3, type: :bytes, deprecated: false)
end
