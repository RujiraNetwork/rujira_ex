defmodule Cosmos.Bank.V1beta1.MsgSend do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:from_address, 1, type: :string, json_name: "fromAddress", deprecated: false)
  field(:to_address, 2, type: :string, json_name: "toAddress", deprecated: false)
  field(:amount, 3, repeated: true, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
end

defmodule Cosmos.Bank.V1beta1.MsgSendResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Bank.V1beta1.MsgMultiSend do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:inputs, 1, repeated: true, type: Cosmos.Bank.V1beta1.Input, deprecated: false)
  field(:outputs, 2, repeated: true, type: Cosmos.Bank.V1beta1.Output, deprecated: false)
end

defmodule Cosmos.Bank.V1beta1.MsgMultiSendResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Bank.V1beta1.MsgUpdateParams do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:authority, 1, type: :string, deprecated: false)
  field(:params, 2, type: Cosmos.Bank.V1beta1.Params, deprecated: false)
end

defmodule Cosmos.Bank.V1beta1.MsgUpdateParamsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Bank.V1beta1.MsgSetSendEnabled do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:authority, 1, type: :string, deprecated: false)

  field(:send_enabled, 2,
    repeated: true,
    type: Cosmos.Bank.V1beta1.SendEnabled,
    json_name: "sendEnabled"
  )

  field(:use_default_for, 3, repeated: true, type: :string, json_name: "useDefaultFor")
end

defmodule Cosmos.Bank.V1beta1.MsgSetSendEnabledResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Bank.V1beta1.Msg.Service do
  @moduledoc false

  use GRPC.Service, name: "cosmos.bank.v1beta1.Msg", protoc_gen_elixir_version: "0.13.0"

  rpc(:Send, Cosmos.Bank.V1beta1.MsgSend, Cosmos.Bank.V1beta1.MsgSendResponse)

  rpc(:MultiSend, Cosmos.Bank.V1beta1.MsgMultiSend, Cosmos.Bank.V1beta1.MsgMultiSendResponse)

  rpc(
    :UpdateParams,
    Cosmos.Bank.V1beta1.MsgUpdateParams,
    Cosmos.Bank.V1beta1.MsgUpdateParamsResponse
  )

  rpc(
    :SetSendEnabled,
    Cosmos.Bank.V1beta1.MsgSetSendEnabled,
    Cosmos.Bank.V1beta1.MsgSetSendEnabledResponse
  )
end

defmodule Cosmos.Bank.V1beta1.Msg.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.Bank.V1beta1.Msg.Service
end
