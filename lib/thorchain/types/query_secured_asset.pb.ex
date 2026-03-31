defmodule Thorchain.Types.QuerySecuredAssetRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asset, 1, type: :string)
  field(:height, 2, type: :string)
end

defmodule Thorchain.Types.QuerySecuredAssetResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asset, 1, type: :string, deprecated: false)
  field(:supply, 2, type: :string, deprecated: false)
  field(:depth, 3, type: :string, deprecated: false)
end

defmodule Thorchain.Types.QuerySecuredAssetsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
end

defmodule Thorchain.Types.QuerySecuredAssetsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:assets, 1, repeated: true, type: Thorchain.Types.QuerySecuredAssetResponse)
end
