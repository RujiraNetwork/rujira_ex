defmodule Thorchain.Types.QuerySwapDetailsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx_id, 1, type: :string, json_name: "txId")
  field(:height, 2, type: :string)
end

defmodule Thorchain.Types.QuerySwapDetailsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:swap, 1, type: Thorchain.Types.MsgSwap)
  field(:status, 2, type: :string)
  field(:queue_type, 3, type: :string, json_name: "queueType")
end
