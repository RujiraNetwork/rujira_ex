defmodule Cosmos.Nft.V1beta1.Class do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:id, 1, type: :string)
  field(:name, 2, type: :string)
  field(:symbol, 3, type: :string)
  field(:description, 4, type: :string)
  field(:uri, 5, type: :string)
  field(:uri_hash, 6, type: :string, json_name: "uriHash")
  field(:data, 7, type: Google.Protobuf.Any)
end

defmodule Cosmos.Nft.V1beta1.NFT do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:class_id, 1, type: :string, json_name: "classId")
  field(:id, 2, type: :string)
  field(:uri, 3, type: :string)
  field(:uri_hash, 4, type: :string, json_name: "uriHash")
  field(:data, 10, type: Google.Protobuf.Any)
end
