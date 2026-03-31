defmodule Thorchain.Types.NodeTssTime do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :bytes, deprecated: false)
  field(:tss_time, 2, type: :int64, json_name: "tssTime")
end

defmodule Thorchain.Types.TssKeygenMetric do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pub_key, 1, type: :string, json_name: "pubKey", deprecated: false)

  field(:node_tss_times, 2,
    repeated: true,
    type: Thorchain.Types.NodeTssTime,
    json_name: "nodeTssTimes",
    deprecated: false
  )
end

defmodule Thorchain.Types.TssKeysignMetric do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx_id, 1, type: :string, json_name: "txId", deprecated: false)

  field(:node_tss_times, 2,
    repeated: true,
    type: Thorchain.Types.NodeTssTime,
    json_name: "nodeTssTimes",
    deprecated: false
  )
end
