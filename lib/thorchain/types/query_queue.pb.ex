defmodule Thorchain.Types.QueryQueueRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
end

defmodule Thorchain.Types.QueryQueueResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:swap, 1, type: :int64, deprecated: false)
  field(:outbound, 2, type: :int64, deprecated: false)
  field(:internal, 3, type: :int64, deprecated: false)

  field(:scheduled_outbound_value, 4,
    type: :string,
    json_name: "scheduledOutboundValue",
    deprecated: false
  )

  field(:scheduled_outbound_clout, 5,
    type: :string,
    json_name: "scheduledOutboundClout",
    deprecated: false
  )
end
