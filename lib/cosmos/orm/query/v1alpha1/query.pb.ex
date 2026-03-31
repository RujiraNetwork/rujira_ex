defmodule Cosmos.Orm.Query.V1alpha1.GetRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:message_name, 1, type: :string, json_name: "messageName")
  field(:index, 2, type: :string)
  field(:values, 3, repeated: true, type: Cosmos.Orm.Query.V1alpha1.IndexValue)
end

defmodule Cosmos.Orm.Query.V1alpha1.GetResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:result, 1, type: Google.Protobuf.Any)
end

defmodule Cosmos.Orm.Query.V1alpha1.ListRequest.Prefix do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:values, 1, repeated: true, type: Cosmos.Orm.Query.V1alpha1.IndexValue)
end

defmodule Cosmos.Orm.Query.V1alpha1.ListRequest.Range do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:start, 1, repeated: true, type: Cosmos.Orm.Query.V1alpha1.IndexValue)
  field(:end, 2, repeated: true, type: Cosmos.Orm.Query.V1alpha1.IndexValue)
end

defmodule Cosmos.Orm.Query.V1alpha1.ListRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  oneof(:query, 0)

  field(:message_name, 1, type: :string, json_name: "messageName")
  field(:index, 2, type: :string)
  field(:prefix, 3, type: Cosmos.Orm.Query.V1alpha1.ListRequest.Prefix, oneof: 0)
  field(:range, 4, type: Cosmos.Orm.Query.V1alpha1.ListRequest.Range, oneof: 0)
  field(:pagination, 5, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Orm.Query.V1alpha1.ListResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:results, 1, repeated: true, type: Google.Protobuf.Any)
  field(:pagination, 5, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Orm.Query.V1alpha1.IndexValue do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  oneof(:value, 0)

  field(:uint, 1, type: :uint64, oneof: 0)
  field(:int, 2, type: :int64, oneof: 0)
  field(:str, 3, type: :string, oneof: 0)
  field(:bytes, 4, type: :bytes, oneof: 0)
  field(:enum, 5, type: :string, oneof: 0)
  field(:bool, 6, type: :bool, oneof: 0)
  field(:timestamp, 7, type: Google.Protobuf.Timestamp, oneof: 0)
  field(:duration, 8, type: Google.Protobuf.Duration, oneof: 0)
end

defmodule Cosmos.Orm.Query.V1alpha1.Query.Service do
  @moduledoc false

  use GRPC.Service, name: "cosmos.orm.query.v1alpha1.Query", protoc_gen_elixir_version: "0.13.0"

  rpc(:Get, Cosmos.Orm.Query.V1alpha1.GetRequest, Cosmos.Orm.Query.V1alpha1.GetResponse)

  rpc(:List, Cosmos.Orm.Query.V1alpha1.ListRequest, Cosmos.Orm.Query.V1alpha1.ListResponse)
end

defmodule Cosmos.Orm.Query.V1alpha1.Query.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.Orm.Query.V1alpha1.Query.Service
end
