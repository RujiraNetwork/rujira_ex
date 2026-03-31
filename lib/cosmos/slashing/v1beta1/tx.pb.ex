defmodule Cosmos.Slashing.V1beta1.MsgUnjail do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:validator_addr, 1, type: :string, json_name: "validatorAddr", deprecated: false)
end

defmodule Cosmos.Slashing.V1beta1.MsgUnjailResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Slashing.V1beta1.MsgUpdateParams do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:authority, 1, type: :string, deprecated: false)
  field(:params, 2, type: Cosmos.Slashing.V1beta1.Params, deprecated: false)
end

defmodule Cosmos.Slashing.V1beta1.MsgUpdateParamsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Slashing.V1beta1.Msg.Service do
  @moduledoc false

  use GRPC.Service, name: "cosmos.slashing.v1beta1.Msg", protoc_gen_elixir_version: "0.13.0"

  rpc(:Unjail, Cosmos.Slashing.V1beta1.MsgUnjail, Cosmos.Slashing.V1beta1.MsgUnjailResponse)

  rpc(
    :UpdateParams,
    Cosmos.Slashing.V1beta1.MsgUpdateParams,
    Cosmos.Slashing.V1beta1.MsgUpdateParamsResponse
  )
end

defmodule Cosmos.Slashing.V1beta1.Msg.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.Slashing.V1beta1.Msg.Service
end
