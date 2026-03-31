defmodule Cosmos.Crisis.V1beta1.MsgVerifyInvariant do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:sender, 1, type: :string, deprecated: false)
  field(:invariant_module_name, 2, type: :string, json_name: "invariantModuleName")
  field(:invariant_route, 3, type: :string, json_name: "invariantRoute")
end

defmodule Cosmos.Crisis.V1beta1.MsgVerifyInvariantResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Crisis.V1beta1.MsgUpdateParams do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:authority, 1, type: :string, deprecated: false)

  field(:constant_fee, 2,
    type: Cosmos.Base.V1beta1.Coin,
    json_name: "constantFee",
    deprecated: false
  )
end

defmodule Cosmos.Crisis.V1beta1.MsgUpdateParamsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Crisis.V1beta1.Msg.Service do
  @moduledoc false

  use GRPC.Service, name: "cosmos.crisis.v1beta1.Msg", protoc_gen_elixir_version: "0.13.0"

  rpc(
    :VerifyInvariant,
    Cosmos.Crisis.V1beta1.MsgVerifyInvariant,
    Cosmos.Crisis.V1beta1.MsgVerifyInvariantResponse
  )

  rpc(
    :UpdateParams,
    Cosmos.Crisis.V1beta1.MsgUpdateParams,
    Cosmos.Crisis.V1beta1.MsgUpdateParamsResponse
  )
end

defmodule Cosmos.Crisis.V1beta1.Msg.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.Crisis.V1beta1.Msg.Service
end
