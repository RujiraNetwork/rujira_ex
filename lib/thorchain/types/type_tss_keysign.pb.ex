defmodule Thorchain.Types.TssKeysignFailVoter do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:id, 1, type: :string, deprecated: false)
  field(:height, 4, type: :int64)
  field(:signers, 6, repeated: true, type: :string)
  field(:last_round_count, 7, type: :int64, json_name: "lastRoundCount")
end
