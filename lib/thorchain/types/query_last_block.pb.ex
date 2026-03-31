defmodule Thorchain.Types.QueryLastBlocksRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
end

defmodule Thorchain.Types.QueryChainsLastBlockRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:chain, 1, type: :string)
  field(:height, 2, type: :string)
end

defmodule Thorchain.Types.QueryLastBlocksResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:last_blocks, 1,
    repeated: true,
    type: Thorchain.Types.ChainsLastBlock,
    json_name: "lastBlocks"
  )
end

defmodule Thorchain.Types.ChainsLastBlock do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:chain, 1, type: :string, deprecated: false)
  field(:last_observed_in, 2, type: :int64, json_name: "lastObservedIn", deprecated: false)
  field(:last_signed_out, 3, type: :int64, json_name: "lastSignedOut", deprecated: false)
  field(:thorchain, 4, type: :int64, deprecated: false)
end
