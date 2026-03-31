defmodule Thorchain.Types.QueryInvariantRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:path, 1, type: :string)
  field(:height, 2, type: :string)
end

defmodule Thorchain.Types.QueryInvariantResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:invariant, 1, type: :string, deprecated: false)
  field(:broken, 2, type: :bool, deprecated: false)
  field(:msg, 3, repeated: true, type: :string, deprecated: false)
end

defmodule Thorchain.Types.QueryInvariantsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
end

defmodule Thorchain.Types.QueryInvariantsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:invariants, 1, repeated: true, type: :string)
end
