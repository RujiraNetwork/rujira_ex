defmodule Thorchain.Bifrost.P2p.Messages.JoinPartyLeaderComm.ResponseType do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:Unknown, 0)
  field(:Success, 1)
  field(:Timeout, 2)
  field(:LeaderNotReady, 3)
  field(:UnknownPeer, 4)
end

defmodule Thorchain.Bifrost.P2p.Messages.JoinPartyRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:ID, 1, type: :string)
end

defmodule Thorchain.Bifrost.P2p.Messages.JoinPartyLeaderComm do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:ID, 1, type: :string)
  field(:MsgType, 2, type: :string)

  field(:type, 3,
    type: Thorchain.Bifrost.P2p.Messages.JoinPartyLeaderComm.ResponseType,
    enum: true
  )

  field(:PeerIDs, 4, repeated: true, type: :string)
end
