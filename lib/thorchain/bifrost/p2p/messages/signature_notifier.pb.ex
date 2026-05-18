defmodule Thorchain.Bifrost.P2p.Messages.KeysignSignature.Status do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:Unknown, 0)
  field(:Success, 1)
  field(:Failed, 2)
end

defmodule Thorchain.Bifrost.P2p.Messages.KeysignSignature do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:ID, 1, type: :string)
  field(:Signatures, 2, repeated: true, type: :bytes)

  field(:KeysignStatus, 3,
    type: Thorchain.Bifrost.P2p.Messages.KeysignSignature.Status,
    enum: true
  )
end
