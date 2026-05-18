defmodule Thorchain.Types.MsgOperatorRotate do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:signer, 1, type: :bytes, deprecated: false)
  field(:operator_address, 2, type: :bytes, json_name: "operatorAddress", deprecated: false)
  field(:coin, 3, type: Thorchain.Common.Coin, deprecated: false)
end
