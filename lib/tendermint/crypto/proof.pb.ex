defmodule Tendermint.Crypto.Proof do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:total, 1, type: :int64)
  field(:index, 2, type: :int64)
  field(:leaf_hash, 3, type: :bytes, json_name: "leafHash")
  field(:aunts, 4, repeated: true, type: :bytes)
end

defmodule Tendermint.Crypto.ValueOp do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:key, 1, type: :bytes)
  field(:proof, 2, type: Tendermint.Crypto.Proof)
end

defmodule Tendermint.Crypto.DominoOp do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:key, 1, type: :string)
  field(:input, 2, type: :string)
  field(:output, 3, type: :string)
end

defmodule Tendermint.Crypto.ProofOp do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:type, 1, type: :string)
  field(:key, 2, type: :bytes)
  field(:data, 3, type: :bytes)
end

defmodule Tendermint.Crypto.ProofOps do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:ops, 1, repeated: true, type: Tendermint.Crypto.ProofOp, deprecated: false)
end
