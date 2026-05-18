defmodule Thorchain.Types.QueryTCYClaimerRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string)
  field(:height, 2, type: :string)
end

defmodule Thorchain.Types.QueryTCYClaimerResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tcy_claimer, 1,
    repeated: true,
    type: Thorchain.Types.QueryTCYClaimer,
    json_name: "tcyClaimer"
  )
end

defmodule Thorchain.Types.QueryTCYClaimer do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asset, 1, type: :string, deprecated: false)
  field(:l1_address, 2, type: :string, json_name: "l1Address")
  field(:amount, 3, type: :string, deprecated: false)
end

defmodule Thorchain.Types.QueryTCYClaimersRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
end

defmodule Thorchain.Types.QueryTCYClaimersResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tcy_claimers, 1,
    repeated: true,
    type: Thorchain.Types.QueryTCYClaimer,
    json_name: "tcyClaimers"
  )
end
