defmodule Cosmos.Auth.V1beta1.MsgUpdateParams do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:authority, 1, type: :string, deprecated: false)
  field(:params, 2, type: Cosmos.Auth.V1beta1.Params, deprecated: false)
end

defmodule Cosmos.Auth.V1beta1.MsgUpdateParamsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Auth.V1beta1.Msg.Service do
  @moduledoc false

  use GRPC.Service, name: "cosmos.auth.v1beta1.Msg", protoc_gen_elixir_version: "0.13.0"

  rpc(
    :UpdateParams,
    Cosmos.Auth.V1beta1.MsgUpdateParams,
    Cosmos.Auth.V1beta1.MsgUpdateParamsResponse
  )
end

defmodule Cosmos.Auth.V1beta1.Msg.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.Auth.V1beta1.Msg.Service
end
