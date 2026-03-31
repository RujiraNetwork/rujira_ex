defmodule Cosmos.Slashing.V1beta1.GenesisState do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:params, 1, type: Cosmos.Slashing.V1beta1.Params, deprecated: false)

  field(:signing_infos, 2,
    repeated: true,
    type: Cosmos.Slashing.V1beta1.SigningInfo,
    json_name: "signingInfos",
    deprecated: false
  )

  field(:missed_blocks, 3,
    repeated: true,
    type: Cosmos.Slashing.V1beta1.ValidatorMissedBlocks,
    json_name: "missedBlocks",
    deprecated: false
  )
end

defmodule Cosmos.Slashing.V1beta1.SigningInfo do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)

  field(:validator_signing_info, 2,
    type: Cosmos.Slashing.V1beta1.ValidatorSigningInfo,
    json_name: "validatorSigningInfo",
    deprecated: false
  )
end

defmodule Cosmos.Slashing.V1beta1.ValidatorMissedBlocks do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)

  field(:missed_blocks, 2,
    repeated: true,
    type: Cosmos.Slashing.V1beta1.MissedBlock,
    json_name: "missedBlocks",
    deprecated: false
  )
end

defmodule Cosmos.Slashing.V1beta1.MissedBlock do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:index, 1, type: :int64)
  field(:missed, 2, type: :bool)
end
