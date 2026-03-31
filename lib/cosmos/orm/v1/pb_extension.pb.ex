defmodule Cosmos.Orm.V1.PbExtension do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.13.0"

  extend(Google.Protobuf.MessageOptions, :table, 104_503_790,
    optional: true,
    type: Cosmos.Orm.V1.TableDescriptor
  )

  extend(Google.Protobuf.MessageOptions, :singleton, 104_503_791,
    optional: true,
    type: Cosmos.Orm.V1.SingletonDescriptor
  )
end
