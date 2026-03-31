defmodule Cosmos.Nft.V1beta1.QueryBalanceRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:class_id, 1, type: :string, json_name: "classId")
  field(:owner, 2, type: :string)
end

defmodule Cosmos.Nft.V1beta1.QueryBalanceResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:amount, 1, type: :uint64)
end

defmodule Cosmos.Nft.V1beta1.QueryOwnerRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:class_id, 1, type: :string, json_name: "classId")
  field(:id, 2, type: :string)
end

defmodule Cosmos.Nft.V1beta1.QueryOwnerResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:owner, 1, type: :string)
end

defmodule Cosmos.Nft.V1beta1.QuerySupplyRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:class_id, 1, type: :string, json_name: "classId")
end

defmodule Cosmos.Nft.V1beta1.QuerySupplyResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:amount, 1, type: :uint64)
end

defmodule Cosmos.Nft.V1beta1.QueryNFTsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:class_id, 1, type: :string, json_name: "classId")
  field(:owner, 2, type: :string)
  field(:pagination, 3, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Nft.V1beta1.QueryNFTsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:nfts, 1, repeated: true, type: Cosmos.Nft.V1beta1.NFT)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Nft.V1beta1.QueryNFTRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:class_id, 1, type: :string, json_name: "classId")
  field(:id, 2, type: :string)
end

defmodule Cosmos.Nft.V1beta1.QueryNFTResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:nft, 1, type: Cosmos.Nft.V1beta1.NFT)
end

defmodule Cosmos.Nft.V1beta1.QueryClassRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:class_id, 1, type: :string, json_name: "classId")
end

defmodule Cosmos.Nft.V1beta1.QueryClassResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:class, 1, type: Cosmos.Nft.V1beta1.Class)
end

defmodule Cosmos.Nft.V1beta1.QueryClassesRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pagination, 1, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Nft.V1beta1.QueryClassesResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:classes, 1, repeated: true, type: Cosmos.Nft.V1beta1.Class)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Nft.V1beta1.Query.Service do
  @moduledoc false

  use GRPC.Service, name: "cosmos.nft.v1beta1.Query", protoc_gen_elixir_version: "0.13.0"

  rpc(:Balance, Cosmos.Nft.V1beta1.QueryBalanceRequest, Cosmos.Nft.V1beta1.QueryBalanceResponse)

  rpc(:Owner, Cosmos.Nft.V1beta1.QueryOwnerRequest, Cosmos.Nft.V1beta1.QueryOwnerResponse)

  rpc(:Supply, Cosmos.Nft.V1beta1.QuerySupplyRequest, Cosmos.Nft.V1beta1.QuerySupplyResponse)

  rpc(:NFTs, Cosmos.Nft.V1beta1.QueryNFTsRequest, Cosmos.Nft.V1beta1.QueryNFTsResponse)

  rpc(:NFT, Cosmos.Nft.V1beta1.QueryNFTRequest, Cosmos.Nft.V1beta1.QueryNFTResponse)

  rpc(:Class, Cosmos.Nft.V1beta1.QueryClassRequest, Cosmos.Nft.V1beta1.QueryClassResponse)

  rpc(:Classes, Cosmos.Nft.V1beta1.QueryClassesRequest, Cosmos.Nft.V1beta1.QueryClassesResponse)
end

defmodule Cosmos.Nft.V1beta1.Query.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.Nft.V1beta1.Query.Service
end
