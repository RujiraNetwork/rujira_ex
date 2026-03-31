defmodule Cosmos.Auth.V1beta1.QueryAccountsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pagination, 1, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Auth.V1beta1.QueryAccountsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:accounts, 1, repeated: true, type: Google.Protobuf.Any, deprecated: false)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Auth.V1beta1.QueryAccountRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)
end

defmodule Cosmos.Auth.V1beta1.QueryAccountResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:account, 1, type: Google.Protobuf.Any, deprecated: false)
end

defmodule Cosmos.Auth.V1beta1.QueryParamsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Auth.V1beta1.QueryParamsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:params, 1, type: Cosmos.Auth.V1beta1.Params, deprecated: false)
end

defmodule Cosmos.Auth.V1beta1.QueryModuleAccountsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Auth.V1beta1.QueryModuleAccountsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:accounts, 1, repeated: true, type: Google.Protobuf.Any, deprecated: false)
end

defmodule Cosmos.Auth.V1beta1.QueryModuleAccountByNameRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:name, 1, type: :string)
end

defmodule Cosmos.Auth.V1beta1.QueryModuleAccountByNameResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:account, 1, type: Google.Protobuf.Any, deprecated: false)
end

defmodule Cosmos.Auth.V1beta1.Bech32PrefixRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Auth.V1beta1.Bech32PrefixResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:bech32_prefix, 1, type: :string, json_name: "bech32Prefix")
end

defmodule Cosmos.Auth.V1beta1.AddressBytesToStringRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address_bytes, 1, type: :bytes, json_name: "addressBytes")
end

defmodule Cosmos.Auth.V1beta1.AddressBytesToStringResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address_string, 1, type: :string, json_name: "addressString")
end

defmodule Cosmos.Auth.V1beta1.AddressStringToBytesRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address_string, 1, type: :string, json_name: "addressString")
end

defmodule Cosmos.Auth.V1beta1.AddressStringToBytesResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address_bytes, 1, type: :bytes, json_name: "addressBytes")
end

defmodule Cosmos.Auth.V1beta1.QueryAccountAddressByIDRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:id, 1, type: :int64, deprecated: true)
  field(:account_id, 2, type: :uint64, json_name: "accountId")
end

defmodule Cosmos.Auth.V1beta1.QueryAccountAddressByIDResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:account_address, 1, type: :string, json_name: "accountAddress", deprecated: false)
end

defmodule Cosmos.Auth.V1beta1.QueryAccountInfoRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)
end

defmodule Cosmos.Auth.V1beta1.QueryAccountInfoResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:info, 1, type: Cosmos.Auth.V1beta1.BaseAccount)
end

defmodule Cosmos.Auth.V1beta1.Query.Service do
  @moduledoc false

  use GRPC.Service, name: "cosmos.auth.v1beta1.Query", protoc_gen_elixir_version: "0.13.0"

  rpc(
    :Accounts,
    Cosmos.Auth.V1beta1.QueryAccountsRequest,
    Cosmos.Auth.V1beta1.QueryAccountsResponse
  )

  rpc(:Account, Cosmos.Auth.V1beta1.QueryAccountRequest, Cosmos.Auth.V1beta1.QueryAccountResponse)

  rpc(
    :AccountAddressByID,
    Cosmos.Auth.V1beta1.QueryAccountAddressByIDRequest,
    Cosmos.Auth.V1beta1.QueryAccountAddressByIDResponse
  )

  rpc(:Params, Cosmos.Auth.V1beta1.QueryParamsRequest, Cosmos.Auth.V1beta1.QueryParamsResponse)

  rpc(
    :ModuleAccounts,
    Cosmos.Auth.V1beta1.QueryModuleAccountsRequest,
    Cosmos.Auth.V1beta1.QueryModuleAccountsResponse
  )

  rpc(
    :ModuleAccountByName,
    Cosmos.Auth.V1beta1.QueryModuleAccountByNameRequest,
    Cosmos.Auth.V1beta1.QueryModuleAccountByNameResponse
  )

  rpc(
    :Bech32Prefix,
    Cosmos.Auth.V1beta1.Bech32PrefixRequest,
    Cosmos.Auth.V1beta1.Bech32PrefixResponse
  )

  rpc(
    :AddressBytesToString,
    Cosmos.Auth.V1beta1.AddressBytesToStringRequest,
    Cosmos.Auth.V1beta1.AddressBytesToStringResponse
  )

  rpc(
    :AddressStringToBytes,
    Cosmos.Auth.V1beta1.AddressStringToBytesRequest,
    Cosmos.Auth.V1beta1.AddressStringToBytesResponse
  )

  rpc(
    :AccountInfo,
    Cosmos.Auth.V1beta1.QueryAccountInfoRequest,
    Cosmos.Auth.V1beta1.QueryAccountInfoResponse
  )
end

defmodule Cosmos.Auth.V1beta1.Query.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.Auth.V1beta1.Query.Service
end
