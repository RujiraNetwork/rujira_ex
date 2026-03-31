defmodule Cosmos.Orm.V1.TableDescriptor do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:primary_key, 1, type: Cosmos.Orm.V1.PrimaryKeyDescriptor, json_name: "primaryKey")
  field(:index, 2, repeated: true, type: Cosmos.Orm.V1.SecondaryIndexDescriptor)
  field(:id, 3, type: :uint32)
end

defmodule Cosmos.Orm.V1.PrimaryKeyDescriptor do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:fields, 1, type: :string)
  field(:auto_increment, 2, type: :bool, json_name: "autoIncrement")
end

defmodule Cosmos.Orm.V1.SecondaryIndexDescriptor do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:fields, 1, type: :string)
  field(:id, 2, type: :uint32)
  field(:unique, 3, type: :bool)
end

defmodule Cosmos.Orm.V1.SingletonDescriptor do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:id, 1, type: :uint32)
end
