defmodule Thorchain.Types.QueryCodesRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string, deprecated: false)
end

defmodule Thorchain.Types.QueryCodesResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:codes, 1, repeated: true, type: Thorchain.Types.QueryCodesCode, deprecated: false)
end

defmodule Thorchain.Types.QueryCodesCode do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:code, 1, type: :string, deprecated: false)
  field(:deployers, 2, repeated: true, type: :string, deprecated: false)
  field(:origin, 3, type: :string, deprecated: false)
end
