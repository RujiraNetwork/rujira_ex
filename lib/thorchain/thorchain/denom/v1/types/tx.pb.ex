defmodule Thorchain.Thorchain.Denom.V1.MsgCreateDenom do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:sender, 1, type: :string, deprecated: false)
  field(:id, 2, type: :string, deprecated: false)
  field(:metadata, 3, type: Cosmos.Bank.V1beta1.Metadata, deprecated: false)
end

defmodule Thorchain.Thorchain.Denom.V1.MsgCreateDenomResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:new_token_denom, 1, type: :string, json_name: "newTokenDenom", deprecated: false)
end

defmodule Thorchain.Thorchain.Denom.V1.MsgMintTokens do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:sender, 1, type: :string, deprecated: false)
  field(:amount, 2, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
  field(:recipient, 3, type: :string, deprecated: false)
end

defmodule Thorchain.Thorchain.Denom.V1.MsgMintTokensResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Thorchain.Thorchain.Denom.V1.MsgBurnTokens do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:sender, 1, type: :string, deprecated: false)
  field(:amount, 2, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
end

defmodule Thorchain.Thorchain.Denom.V1.MsgBurnTokensResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Thorchain.Thorchain.Denom.V1.MsgChangeDenomAdmin do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:sender, 1, type: :string, deprecated: false)
  field(:denom, 2, type: :string, deprecated: false)
  field(:newAdmin, 3, type: :string, deprecated: false)
end

defmodule Thorchain.Thorchain.Denom.V1.MsgChangeDenomAdminResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Thorchain.Thorchain.Denom.V1.Msg.Service do
  @moduledoc false

  use GRPC.Service, name: "thorchain.denom.v1.Msg", protoc_gen_elixir_version: "0.13.0"

  rpc(
    :CreateDenom,
    Thorchain.Thorchain.Denom.V1.MsgCreateDenom,
    Thorchain.Thorchain.Denom.V1.MsgCreateDenomResponse
  )

  rpc(
    :MintTokens,
    Thorchain.Thorchain.Denom.V1.MsgMintTokens,
    Thorchain.Thorchain.Denom.V1.MsgMintTokensResponse
  )

  rpc(
    :BurnTokens,
    Thorchain.Thorchain.Denom.V1.MsgBurnTokens,
    Thorchain.Thorchain.Denom.V1.MsgBurnTokensResponse
  )

  rpc(
    :ChangeDenomAdmin,
    Thorchain.Thorchain.Denom.V1.MsgChangeDenomAdmin,
    Thorchain.Thorchain.Denom.V1.MsgChangeDenomAdminResponse
  )
end

defmodule Thorchain.Thorchain.Denom.V1.Msg.Stub do
  @moduledoc false

  use GRPC.Stub, service: Thorchain.Thorchain.Denom.V1.Msg.Service
end
