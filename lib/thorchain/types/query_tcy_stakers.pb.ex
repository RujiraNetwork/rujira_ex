defmodule Thorchain.Types.QueryTCYStakerRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string)
  field(:height, 2, type: :string)
end

defmodule Thorchain.Types.QueryTCYStakerResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string)
  field(:amount, 2, type: :string, deprecated: false)
end

defmodule Thorchain.Types.QueryTCYStakersRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
end

defmodule Thorchain.Types.QueryTCYStakersResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tcy_stakers, 1,
    repeated: true,
    type: Thorchain.Types.QueryTCYStakerResponse,
    json_name: "tcyStakers"
  )
end
