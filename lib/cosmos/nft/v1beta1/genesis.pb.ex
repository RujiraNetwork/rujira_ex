defmodule Cosmos.Nft.V1beta1.GenesisState do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:classes, 1, repeated: true, type: Cosmos.Nft.V1beta1.Class)
  field(:entries, 2, repeated: true, type: Cosmos.Nft.V1beta1.Entry)
end

defmodule Cosmos.Nft.V1beta1.Entry do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:owner, 1, type: :string)
  field(:nfts, 2, repeated: true, type: Cosmos.Nft.V1beta1.NFT)
end
