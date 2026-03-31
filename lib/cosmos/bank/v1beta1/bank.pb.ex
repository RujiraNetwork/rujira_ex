defmodule Cosmos.Bank.V1beta1.Params do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:send_enabled, 1,
    repeated: true,
    type: Cosmos.Bank.V1beta1.SendEnabled,
    json_name: "sendEnabled",
    deprecated: true
  )

  field(:default_send_enabled, 2, type: :bool, json_name: "defaultSendEnabled")
end

defmodule Cosmos.Bank.V1beta1.SendEnabled do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:denom, 1, type: :string)
  field(:enabled, 2, type: :bool)
end

defmodule Cosmos.Bank.V1beta1.Input do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)
  field(:coins, 2, repeated: true, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
end

defmodule Cosmos.Bank.V1beta1.Output do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)
  field(:coins, 2, repeated: true, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
end

defmodule Cosmos.Bank.V1beta1.Supply do
  @moduledoc false

  use Protobuf, deprecated: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:total, 1, repeated: true, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
end

defmodule Cosmos.Bank.V1beta1.DenomUnit do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:denom, 1, type: :string)
  field(:exponent, 2, type: :uint32)
  field(:aliases, 3, repeated: true, type: :string)
end

defmodule Cosmos.Bank.V1beta1.Metadata do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:description, 1, type: :string)

  field(:denom_units, 2,
    repeated: true,
    type: Cosmos.Bank.V1beta1.DenomUnit,
    json_name: "denomUnits"
  )

  field(:base, 3, type: :string)
  field(:display, 4, type: :string)
  field(:name, 5, type: :string)
  field(:symbol, 6, type: :string)
  field(:uri, 7, type: :string, deprecated: false)
  field(:uri_hash, 8, type: :string, json_name: "uriHash", deprecated: false)
end
