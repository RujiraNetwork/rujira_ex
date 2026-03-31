defmodule Thorchain.Types.QueryOutboundFeeRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asset, 1, type: :string)
  field(:height, 2, type: :string)
end

defmodule Thorchain.Types.QueryOutboundFeeResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asset, 1, type: :string, deprecated: false)
  field(:outbound_fee, 2, type: :string, json_name: "outboundFee", deprecated: false)
  field(:fee_withheld_rune, 3, type: :string, json_name: "feeWithheldRune")
  field(:fee_spent_rune, 4, type: :string, json_name: "feeSpentRune")
  field(:surplus_rune, 5, type: :string, json_name: "surplusRune")

  field(:dynamic_multiplier_basis_points, 6,
    type: :string,
    json_name: "dynamicMultiplierBasisPoints"
  )
end

defmodule Thorchain.Types.QueryOutboundFeesRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
end

defmodule Thorchain.Types.QueryOutboundFeesResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:outbound_fees, 1,
    repeated: true,
    type: Thorchain.Types.QueryOutboundFeeResponse,
    json_name: "outboundFees"
  )
end
