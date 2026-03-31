defmodule Thorchain.Oracle.Query.Service do
  @moduledoc false

  use GRPC.Service, name: "oracle.Query", protoc_gen_elixir_version: "0.13.0"

  rpc(:Price, Thorchain.Oracle.QueryOraclePriceRequest, Thorchain.Oracle.QueryOraclePriceResponse)
end

defmodule Thorchain.Oracle.Query.Stub do
  @moduledoc false

  use GRPC.Stub, service: Thorchain.Oracle.Query.Service
end
