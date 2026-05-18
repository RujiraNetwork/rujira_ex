defmodule Thorchain.Types.QueryBlockRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
end

defmodule Thorchain.Types.QueryBlockResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:id, 1, type: Thorchain.Types.BlockResponseId, deprecated: false)
  field(:header, 2, type: Thorchain.Types.BlockResponseHeader, deprecated: false)

  field(:begin_block_events, 3,
    repeated: true,
    type: Thorchain.Types.BlockEvent,
    json_name: "beginBlockEvents",
    deprecated: false
  )

  field(:end_block_events, 4,
    repeated: true,
    type: Thorchain.Types.BlockEvent,
    json_name: "endBlockEvents",
    deprecated: false
  )

  field(:finalize_block_events, 6,
    repeated: true,
    type: Thorchain.Types.BlockEvent,
    json_name: "finalizeBlockEvents",
    deprecated: false
  )

  field(:txs, 5, repeated: true, type: Thorchain.Types.QueryBlockTx, deprecated: false)
end

defmodule Thorchain.Types.BlockResponseId do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:hash, 1, type: :string, deprecated: false)
  field(:parts, 2, type: Thorchain.Types.BlockResponseIdParts, deprecated: false)
end

defmodule Thorchain.Types.BlockResponseIdParts do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:total, 1, type: :int64, deprecated: false)
  field(:hash, 2, type: :string, deprecated: false)
end

defmodule Thorchain.Types.BlockResponseHeader do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:version, 1, type: Thorchain.Types.BlockResponseHeaderVersion, deprecated: false)
  field(:chain_id, 2, type: :string, json_name: "chainId", deprecated: false)
  field(:height, 3, type: :int64, deprecated: false)
  field(:time, 4, type: :string, deprecated: false)

  field(:last_block_id, 5,
    type: Thorchain.Types.BlockResponseId,
    json_name: "lastBlockId",
    deprecated: false
  )

  field(:last_commit_hash, 6, type: :string, json_name: "lastCommitHash", deprecated: false)
  field(:data_hash, 7, type: :string, json_name: "dataHash", deprecated: false)
  field(:validators_hash, 8, type: :string, json_name: "validatorsHash", deprecated: false)

  field(:next_validators_hash, 9,
    type: :string,
    json_name: "nextValidatorsHash",
    deprecated: false
  )

  field(:consensus_hash, 10, type: :string, json_name: "consensusHash", deprecated: false)
  field(:app_hash, 11, type: :string, json_name: "appHash", deprecated: false)
  field(:last_results_hash, 12, type: :string, json_name: "lastResultsHash", deprecated: false)
  field(:evidence_hash, 13, type: :string, json_name: "evidenceHash", deprecated: false)
  field(:proposer_address, 14, type: :string, json_name: "proposerAddress", deprecated: false)
end

defmodule Thorchain.Types.BlockResponseHeaderVersion do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:block, 1, type: :string, deprecated: false)
  field(:app, 2, type: :string, deprecated: false)
end

defmodule Thorchain.Types.BlockEvent do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:event_kv_pair, 1,
    repeated: true,
    type: Thorchain.Types.EventKeyValuePair,
    json_name: "eventKvPair"
  )
end

defmodule Thorchain.Types.EventKeyValuePair do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:key, 1, type: :string)
  field(:value, 2, type: :string)
end

defmodule Thorchain.Types.QueryBlockTx do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:hash, 1, type: :string, deprecated: false)
  field(:tx, 2, type: :bytes)
  field(:result, 3, type: Thorchain.Types.BlockTxResult, deprecated: false)
end

defmodule Thorchain.Types.BlockTxResult do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:code, 1, type: :int64, deprecated: false)
  field(:data, 2, type: :string)
  field(:log, 3, type: :string)
  field(:info, 4, type: :string)
  field(:gas_wanted, 5, type: :string, json_name: "gasWanted")
  field(:gas_used, 6, type: :string, json_name: "gasUsed")
  field(:events, 7, repeated: true, type: Thorchain.Types.BlockEvent)
  field(:codespace, 8, type: :string)
end
