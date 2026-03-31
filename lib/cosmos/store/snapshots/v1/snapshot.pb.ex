defmodule Cosmos.Store.Snapshots.V1.Snapshot do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :uint64)
  field(:format, 2, type: :uint32)
  field(:chunks, 3, type: :uint32)
  field(:hash, 4, type: :bytes)
  field(:metadata, 5, type: Cosmos.Store.Snapshots.V1.Metadata, deprecated: false)
end

defmodule Cosmos.Store.Snapshots.V1.Metadata do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:chunk_hashes, 1, repeated: true, type: :bytes, json_name: "chunkHashes")
end

defmodule Cosmos.Store.Snapshots.V1.SnapshotItem do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  oneof(:item, 0)

  field(:store, 1, type: Cosmos.Store.Snapshots.V1.SnapshotStoreItem, oneof: 0)
  field(:iavl, 2, type: Cosmos.Store.Snapshots.V1.SnapshotIAVLItem, oneof: 0, deprecated: false)
  field(:extension, 3, type: Cosmos.Store.Snapshots.V1.SnapshotExtensionMeta, oneof: 0)

  field(:extension_payload, 4,
    type: Cosmos.Store.Snapshots.V1.SnapshotExtensionPayload,
    json_name: "extensionPayload",
    oneof: 0
  )
end

defmodule Cosmos.Store.Snapshots.V1.SnapshotStoreItem do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:name, 1, type: :string)
end

defmodule Cosmos.Store.Snapshots.V1.SnapshotIAVLItem do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:key, 1, type: :bytes)
  field(:value, 2, type: :bytes)
  field(:version, 3, type: :int64)
  field(:height, 4, type: :int32)
end

defmodule Cosmos.Store.Snapshots.V1.SnapshotExtensionMeta do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:name, 1, type: :string)
  field(:format, 2, type: :uint32)
end

defmodule Cosmos.Store.Snapshots.V1.SnapshotExtensionPayload do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:payload, 1, type: :bytes)
end
