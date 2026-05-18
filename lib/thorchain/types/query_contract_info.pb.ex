defmodule Thorchain.Types.QueryContractInfoRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field :height, 1, type: :string
  field :address, 2, type: :string
end

defmodule Thorchain.Types.QueryContractInfoResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field :info, 1, type: Thorchain.Types.ContractInfo
end

defmodule Thorchain.Types.QueryContractInfosRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field :height, 1, type: :string
  field :contract, 2, type: :string
  field :version, 3, type: :string
end

defmodule Thorchain.Types.QueryContractInfosResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field :infos, 1, repeated: true, type: Thorchain.Types.ContractInfo
end
