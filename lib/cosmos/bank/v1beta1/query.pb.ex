defmodule Cosmos.Bank.V1beta1.QueryBalanceRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)
  field(:denom, 2, type: :string)
end

defmodule Cosmos.Bank.V1beta1.QueryBalanceResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:balance, 1, type: Cosmos.Base.V1beta1.Coin)
end

defmodule Cosmos.Bank.V1beta1.QueryAllBalancesRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageRequest)
  field(:resolve_denom, 3, type: :bool, json_name: "resolveDenom")
end

defmodule Cosmos.Bank.V1beta1.QueryAllBalancesResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:balances, 1, repeated: true, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Bank.V1beta1.QuerySpendableBalancesRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Bank.V1beta1.QuerySpendableBalancesResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:balances, 1, repeated: true, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Bank.V1beta1.QuerySpendableBalanceByDenomRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)
  field(:denom, 2, type: :string)
end

defmodule Cosmos.Bank.V1beta1.QuerySpendableBalanceByDenomResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:balance, 1, type: Cosmos.Base.V1beta1.Coin)
end

defmodule Cosmos.Bank.V1beta1.QueryTotalSupplyRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pagination, 1, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Bank.V1beta1.QueryTotalSupplyResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:supply, 1, repeated: true, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Bank.V1beta1.QuerySupplyOfRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:denom, 1, type: :string)
end

defmodule Cosmos.Bank.V1beta1.QuerySupplyOfResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:amount, 1, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
end

defmodule Cosmos.Bank.V1beta1.QueryParamsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Bank.V1beta1.QueryParamsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:params, 1, type: Cosmos.Bank.V1beta1.Params, deprecated: false)
end

defmodule Cosmos.Bank.V1beta1.QueryDenomsMetadataRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pagination, 1, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Bank.V1beta1.QueryDenomsMetadataResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:metadatas, 1, repeated: true, type: Cosmos.Bank.V1beta1.Metadata, deprecated: false)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Bank.V1beta1.QueryDenomMetadataRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:denom, 1, type: :string)
end

defmodule Cosmos.Bank.V1beta1.QueryDenomMetadataResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:metadata, 1, type: Cosmos.Bank.V1beta1.Metadata, deprecated: false)
end

defmodule Cosmos.Bank.V1beta1.QueryDenomMetadataByQueryStringRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:denom, 1, type: :string)
end

defmodule Cosmos.Bank.V1beta1.QueryDenomMetadataByQueryStringResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:metadata, 1, type: Cosmos.Bank.V1beta1.Metadata, deprecated: false)
end

defmodule Cosmos.Bank.V1beta1.QueryDenomOwnersRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:denom, 1, type: :string)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Bank.V1beta1.DenomOwner do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)
  field(:balance, 2, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
end

defmodule Cosmos.Bank.V1beta1.QueryDenomOwnersResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:denom_owners, 1,
    repeated: true,
    type: Cosmos.Bank.V1beta1.DenomOwner,
    json_name: "denomOwners"
  )

  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Bank.V1beta1.QueryDenomOwnersByQueryRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:denom, 1, type: :string)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Bank.V1beta1.QueryDenomOwnersByQueryResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:denom_owners, 1,
    repeated: true,
    type: Cosmos.Bank.V1beta1.DenomOwner,
    json_name: "denomOwners"
  )

  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Bank.V1beta1.QuerySendEnabledRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:denoms, 1, repeated: true, type: :string)
  field(:pagination, 99, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Bank.V1beta1.QuerySendEnabledResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:send_enabled, 1,
    repeated: true,
    type: Cosmos.Bank.V1beta1.SendEnabled,
    json_name: "sendEnabled"
  )

  field(:pagination, 99, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Bank.V1beta1.Query.Service do
  @moduledoc false

  use GRPC.Service, name: "cosmos.bank.v1beta1.Query", protoc_gen_elixir_version: "0.13.0"

  rpc(:Balance, Cosmos.Bank.V1beta1.QueryBalanceRequest, Cosmos.Bank.V1beta1.QueryBalanceResponse)

  rpc(
    :AllBalances,
    Cosmos.Bank.V1beta1.QueryAllBalancesRequest,
    Cosmos.Bank.V1beta1.QueryAllBalancesResponse
  )

  rpc(
    :SpendableBalances,
    Cosmos.Bank.V1beta1.QuerySpendableBalancesRequest,
    Cosmos.Bank.V1beta1.QuerySpendableBalancesResponse
  )

  rpc(
    :SpendableBalanceByDenom,
    Cosmos.Bank.V1beta1.QuerySpendableBalanceByDenomRequest,
    Cosmos.Bank.V1beta1.QuerySpendableBalanceByDenomResponse
  )

  rpc(
    :TotalSupply,
    Cosmos.Bank.V1beta1.QueryTotalSupplyRequest,
    Cosmos.Bank.V1beta1.QueryTotalSupplyResponse
  )

  rpc(
    :SupplyOf,
    Cosmos.Bank.V1beta1.QuerySupplyOfRequest,
    Cosmos.Bank.V1beta1.QuerySupplyOfResponse
  )

  rpc(:Params, Cosmos.Bank.V1beta1.QueryParamsRequest, Cosmos.Bank.V1beta1.QueryParamsResponse)

  rpc(
    :DenomMetadata,
    Cosmos.Bank.V1beta1.QueryDenomMetadataRequest,
    Cosmos.Bank.V1beta1.QueryDenomMetadataResponse
  )

  rpc(
    :DenomMetadataByQueryString,
    Cosmos.Bank.V1beta1.QueryDenomMetadataByQueryStringRequest,
    Cosmos.Bank.V1beta1.QueryDenomMetadataByQueryStringResponse
  )

  rpc(
    :DenomsMetadata,
    Cosmos.Bank.V1beta1.QueryDenomsMetadataRequest,
    Cosmos.Bank.V1beta1.QueryDenomsMetadataResponse
  )

  rpc(
    :DenomOwners,
    Cosmos.Bank.V1beta1.QueryDenomOwnersRequest,
    Cosmos.Bank.V1beta1.QueryDenomOwnersResponse
  )

  rpc(
    :DenomOwnersByQuery,
    Cosmos.Bank.V1beta1.QueryDenomOwnersByQueryRequest,
    Cosmos.Bank.V1beta1.QueryDenomOwnersByQueryResponse
  )

  rpc(
    :SendEnabled,
    Cosmos.Bank.V1beta1.QuerySendEnabledRequest,
    Cosmos.Bank.V1beta1.QuerySendEnabledResponse
  )
end

defmodule Cosmos.Bank.V1beta1.Query.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.Bank.V1beta1.Query.Service
end
