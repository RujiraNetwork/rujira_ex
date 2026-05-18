defmodule Thorchain.Types.MsgErrataTx do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx_id, 1, type: :string, json_name: "txId", deprecated: false)
  field(:chain, 2, type: :string, deprecated: false)
  field(:signer, 3, type: :bytes, deprecated: false)
end

defmodule Thorchain.Types.MsgErrataTxQuorum do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:quoErrata, 1, type: Thorchain.Common.QuorumErrataTx)
  field(:signer, 2, type: :bytes, deprecated: false)
end
