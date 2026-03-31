defmodule Cosmos.Feegrant.V1beta1.BasicAllowance do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:spend_limit, 1,
    repeated: true,
    type: Cosmos.Base.V1beta1.Coin,
    json_name: "spendLimit",
    deprecated: false
  )

  field(:expiration, 2, type: Google.Protobuf.Timestamp, deprecated: false)
end

defmodule Cosmos.Feegrant.V1beta1.PeriodicAllowance do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:basic, 1, type: Cosmos.Feegrant.V1beta1.BasicAllowance, deprecated: false)
  field(:period, 2, type: Google.Protobuf.Duration, deprecated: false)

  field(:period_spend_limit, 3,
    repeated: true,
    type: Cosmos.Base.V1beta1.Coin,
    json_name: "periodSpendLimit",
    deprecated: false
  )

  field(:period_can_spend, 4,
    repeated: true,
    type: Cosmos.Base.V1beta1.Coin,
    json_name: "periodCanSpend",
    deprecated: false
  )

  field(:period_reset, 5,
    type: Google.Protobuf.Timestamp,
    json_name: "periodReset",
    deprecated: false
  )
end

defmodule Cosmos.Feegrant.V1beta1.AllowedMsgAllowance do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:allowance, 1, type: Google.Protobuf.Any, deprecated: false)
  field(:allowed_messages, 2, repeated: true, type: :string, json_name: "allowedMessages")
end

defmodule Cosmos.Feegrant.V1beta1.Grant do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:granter, 1, type: :string, deprecated: false)
  field(:grantee, 2, type: :string, deprecated: false)
  field(:allowance, 3, type: Google.Protobuf.Any, deprecated: false)
end
