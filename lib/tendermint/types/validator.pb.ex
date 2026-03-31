defmodule Tendermint.Types.BlockIDFlag do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:BLOCK_ID_FLAG_UNKNOWN, 0)
  field(:BLOCK_ID_FLAG_ABSENT, 1)
  field(:BLOCK_ID_FLAG_COMMIT, 2)
  field(:BLOCK_ID_FLAG_NIL, 3)
end

defmodule Tendermint.Types.ValidatorSet do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:validators, 1, repeated: true, type: Tendermint.Types.Validator)
  field(:proposer, 2, type: Tendermint.Types.Validator)
  field(:total_voting_power, 3, type: :int64, json_name: "totalVotingPower")
end

defmodule Tendermint.Types.Validator do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :bytes)
  field(:pub_key, 2, type: Tendermint.Crypto.PublicKey, json_name: "pubKey", deprecated: false)
  field(:voting_power, 3, type: :int64, json_name: "votingPower")
  field(:proposer_priority, 4, type: :int64, json_name: "proposerPriority")
end

defmodule Tendermint.Types.SimpleValidator do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pub_key, 1, type: Tendermint.Crypto.PublicKey, json_name: "pubKey")
  field(:voting_power, 2, type: :int64, json_name: "votingPower")
end
