defmodule Thorchain.Types.MsgRunePoolDeposit do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:signer, 1, type: :bytes, deprecated: false)
  field(:tx, 2, type: Thorchain.Common.Tx, deprecated: false)
end

defmodule Thorchain.Types.MsgRunePoolWithdraw do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:signer, 1, type: :bytes, deprecated: false)
  field(:tx, 2, type: Thorchain.Common.Tx, deprecated: false)
  field(:basis_points, 3, type: :string, json_name: "basisPoints", deprecated: false)
  field(:affiliate_address, 4, type: :string, json_name: "affiliateAddress", deprecated: false)

  field(:affiliate_basis_points, 5,
    type: :string,
    json_name: "affiliateBasisPoints",
    deprecated: false
  )
end
