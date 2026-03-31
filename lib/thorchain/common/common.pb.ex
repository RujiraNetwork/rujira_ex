defmodule Thorchain.Common.Asset do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:chain, 1, type: :string, deprecated: false)
  field(:symbol, 2, type: :string, deprecated: false)
  field(:ticker, 3, type: :string, deprecated: false)
  field(:synth, 4, type: :bool)
  field(:trade, 5, type: :bool)
  field(:secured, 6, type: :bool)
end

defmodule Thorchain.Common.Coin do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asset, 1, type: Thorchain.Common.Asset, deprecated: false)
  field(:amount, 2, type: :string, deprecated: false)
  field(:decimals, 3, type: :int64)
end

defmodule Thorchain.Common.PubKeySet do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:secp256k1, 1, type: :string, deprecated: false)
  field(:ed25519, 2, type: :string, deprecated: false)
end

defmodule Thorchain.Common.Tx do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:id, 1, type: :string, deprecated: false)
  field(:chain, 2, type: :string, deprecated: false)
  field(:from_address, 3, type: :string, json_name: "fromAddress", deprecated: false)
  field(:to_address, 4, type: :string, json_name: "toAddress", deprecated: false)
  field(:coins, 5, repeated: true, type: Thorchain.Common.Coin, deprecated: false)
  field(:gas, 6, repeated: true, type: Thorchain.Common.Coin, deprecated: false)
  field(:memo, 7, type: :string)
end

defmodule Thorchain.Common.Fee do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:coins, 1, repeated: true, type: Thorchain.Common.Coin, deprecated: false)
  field(:pool_deduct, 2, type: :string, json_name: "poolDeduct", deprecated: false)
end

defmodule Thorchain.Common.ProtoUint do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:value, 1, type: :string, deprecated: false)
end
