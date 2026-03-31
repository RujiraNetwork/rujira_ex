defmodule Thorchain.Types.MsgTssKeysignFail do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:id, 1, type: :string, deprecated: false)
  field(:height, 2, type: :int64)
  field(:blame, 3, type: Thorchain.Types.Blame, deprecated: false)
  field(:memo, 4, type: :string)
  field(:coins, 5, repeated: true, type: Thorchain.Common.Coin, deprecated: false)
  field(:pub_key, 6, type: :string, json_name: "pubKey", deprecated: false)
  field(:signer, 7, type: :bytes, deprecated: false)
end
