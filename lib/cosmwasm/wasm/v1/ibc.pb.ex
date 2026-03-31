defmodule Cosmwasm.Wasm.V1.MsgIBCSend do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:channel, 2, type: :string, deprecated: false)
  field(:timeout_height, 4, type: :uint64, json_name: "timeoutHeight", deprecated: false)
  field(:timeout_timestamp, 5, type: :uint64, json_name: "timeoutTimestamp", deprecated: false)
  field(:data, 6, type: :bytes)
end

defmodule Cosmwasm.Wasm.V1.MsgIBCSendResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:sequence, 1, type: :uint64)
end

defmodule Cosmwasm.Wasm.V1.MsgIBCWriteAcknowledgementResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmwasm.Wasm.V1.MsgIBCCloseChannel do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:channel, 2, type: :string, deprecated: false)
end
