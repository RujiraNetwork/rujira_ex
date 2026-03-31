defmodule Thorchain.Types.MsgSetNodeKeys do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pub_key_set_set, 1,
    type: Thorchain.Common.PubKeySet,
    json_name: "pubKeySetSet",
    deprecated: false
  )

  field(:validator_cons_pub_key, 2, type: :string, json_name: "validatorConsPubKey")
  field(:signer, 3, type: :bytes, deprecated: false)
end
