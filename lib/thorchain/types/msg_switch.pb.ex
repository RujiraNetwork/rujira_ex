defmodule Thorchain.Types.MsgSwitch do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx, 1, type: Thorchain.Common.Tx, deprecated: false)
  field(:asset, 2, type: Thorchain.Common.Asset, deprecated: false)
  field(:amount, 3, type: :string, deprecated: false)
  field(:address, 4, type: :bytes, deprecated: false)
  field(:signer, 5, type: :bytes, deprecated: false)
end
