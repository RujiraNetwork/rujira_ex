defmodule Cosmos.Nft.V1beta1.MsgSend do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:class_id, 1, type: :string, json_name: "classId")
  field(:id, 2, type: :string)
  field(:sender, 3, type: :string, deprecated: false)
  field(:receiver, 4, type: :string, deprecated: false)
end

defmodule Cosmos.Nft.V1beta1.MsgSendResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Nft.V1beta1.Msg.Service do
  @moduledoc false

  use GRPC.Service, name: "cosmos.nft.v1beta1.Msg", protoc_gen_elixir_version: "0.13.0"

  rpc(:Send, Cosmos.Nft.V1beta1.MsgSend, Cosmos.Nft.V1beta1.MsgSendResponse)
end

defmodule Cosmos.Nft.V1beta1.Msg.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.Nft.V1beta1.Msg.Service
end
