defmodule Thorchain.Types.MsgTssPool do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:id, 1, type: :string, deprecated: false)
  field(:pool_pub_key, 2, type: :string, json_name: "poolPubKey", deprecated: false)

  field(:keygen_type, 3,
    type: Thorchain.Types.KeygenType,
    json_name: "keygenType",
    enum: true,
    deprecated: false
  )

  field(:pub_keys, 4, repeated: true, type: :string, json_name: "pubKeys")
  field(:height, 5, type: :int64)
  field(:blame, 6, repeated: true, type: Thorchain.Types.Blame, deprecated: false)
  field(:chains, 7, repeated: true, type: :string)
  field(:signer, 8, type: :bytes, deprecated: false)
  field(:keygen_time, 9, type: :int64, json_name: "keygenTime")
  field(:keyshares_backup, 10, type: :bytes, json_name: "keysharesBackup")
  field(:secp256k1_signature, 11, type: :bytes, json_name: "secp256k1Signature")
  field(:pool_pub_key_eddsa, 12, type: :string, json_name: "poolPubKeyEddsa", deprecated: false)

  field(:keyshares_backup_eddsa, 13,
    type: :bytes,
    json_name: "keysharesBackupEddsa",
    deprecated: false
  )
end
