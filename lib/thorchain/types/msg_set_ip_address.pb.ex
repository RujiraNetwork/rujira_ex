defmodule Thorchain.Types.MsgSetIPAddress do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:ip_address, 1, type: :string, json_name: "ipAddress", deprecated: false)
  field(:signer, 2, type: :bytes, deprecated: false)
end
