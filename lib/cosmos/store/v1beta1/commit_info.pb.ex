defmodule Cosmos.Store.V1beta1.CommitInfo do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:version, 1, type: :int64)

  field(:store_infos, 2,
    repeated: true,
    type: Cosmos.Store.V1beta1.StoreInfo,
    json_name: "storeInfos",
    deprecated: false
  )

  field(:timestamp, 3, type: Google.Protobuf.Timestamp, deprecated: false)
end

defmodule Cosmos.Store.V1beta1.StoreInfo do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:name, 1, type: :string)

  field(:commit_id, 2,
    type: Cosmos.Store.V1beta1.CommitID,
    json_name: "commitId",
    deprecated: false
  )
end

defmodule Cosmos.Store.V1beta1.CommitID do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:version, 1, type: :int64)
  field(:hash, 2, type: :bytes)
end
