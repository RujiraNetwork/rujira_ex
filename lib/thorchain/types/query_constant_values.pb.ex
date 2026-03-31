defmodule Thorchain.Types.QueryConstantValuesRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
end

defmodule Thorchain.Types.QueryConstantValuesResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:int_64_values, 1,
    repeated: true,
    type: Thorchain.Types.Int64Constants,
    json_name: "int64Values"
  )

  field(:bool_values, 2,
    repeated: true,
    type: Thorchain.Types.BoolConstants,
    json_name: "boolValues"
  )

  field(:string_values, 3,
    repeated: true,
    type: Thorchain.Types.StringConstants,
    json_name: "stringValues"
  )
end

defmodule Thorchain.Types.Int64Constants do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:name, 1, type: :string)
  field(:value, 2, type: :int64)
end

defmodule Thorchain.Types.BoolConstants do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:name, 1, type: :string)
  field(:value, 2, type: :bool)
end

defmodule Thorchain.Types.StringConstants do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:name, 1, type: :string)
  field(:value, 2, type: :string)
end
