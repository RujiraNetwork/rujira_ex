defmodule Thorchain.Types.MsgSend do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:from_address, 1, type: :bytes, json_name: "fromAddress", deprecated: false)
  field(:to_address, 2, type: :bytes, json_name: "toAddress", deprecated: false)
  field(:amount, 3, repeated: true, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
end
