defmodule Thorchain.Types.MsgPriceFeedQuorum do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:quoPriceFeed, 1, type: Thorchain.Common.QuorumPriceFeed)
  field(:signer, 2, type: :bytes, deprecated: false)
end

defmodule Thorchain.Types.MsgPriceFeedQuorumBatch do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:quoPriceFeeds, 1, repeated: true, type: Thorchain.Common.QuorumPriceFeed)
  field(:signer, 2, type: :bytes, deprecated: false)
end
