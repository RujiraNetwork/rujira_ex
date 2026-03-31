defmodule Thorchain.Types.QueryTxStagesRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx_id, 1, type: :string, json_name: "txId")
  field(:height, 2, type: :string)
end

defmodule Thorchain.Types.QueryTxStagesResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:inbound_observed, 1,
    type: Thorchain.Types.InboundObservedStage,
    json_name: "inboundObserved",
    deprecated: false
  )

  field(:inbound_confirmation_counted, 2,
    type: Thorchain.Types.InboundConfirmationCountedStage,
    json_name: "inboundConfirmationCounted"
  )

  field(:inbound_finalised, 3,
    type: Thorchain.Types.InboundFinalisedStage,
    json_name: "inboundFinalised"
  )

  field(:swap_status, 4, type: Thorchain.Types.SwapStatus, json_name: "swapStatus")
  field(:swap_finalised, 5, type: Thorchain.Types.SwapFinalisedStage, json_name: "swapFinalised")
  field(:outbound_delay, 6, type: Thorchain.Types.OutboundDelayStage, json_name: "outboundDelay")

  field(:outbound_signed, 7,
    type: Thorchain.Types.OutboundSignedStage,
    json_name: "outboundSigned"
  )
end

defmodule Thorchain.Types.QueryTxStatusRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx_id, 1, type: :string, json_name: "txId")
  field(:height, 2, type: :string)
end

defmodule Thorchain.Types.QueryTxStatusResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx, 1, type: Thorchain.Common.Tx)

  field(:planned_out_txs, 2,
    repeated: true,
    type: Thorchain.Types.PlannedOutTx,
    json_name: "plannedOutTxs"
  )

  field(:out_txs, 3,
    repeated: true,
    type: Thorchain.Common.Tx,
    json_name: "outTxs",
    deprecated: false
  )

  field(:stages, 4, type: Thorchain.Types.QueryTxStagesResponse, deprecated: false)
end

defmodule Thorchain.Types.QueryTxRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx_id, 1, type: :string, json_name: "txId")
  field(:height, 2, type: :string)
end

defmodule Thorchain.Types.QueryTxResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:observed_tx, 1,
    type: Thorchain.Types.QueryObservedTx,
    json_name: "observedTx",
    deprecated: false
  )

  field(:consensus_height, 2, type: :int64, json_name: "consensusHeight")
  field(:finalised_height, 3, type: :int64, json_name: "finalisedHeight")
  field(:outbound_height, 4, type: :int64, json_name: "outboundHeight")

  field(:keysign_metric, 5,
    type: Thorchain.Types.TssKeysignMetric,
    json_name: "keysignMetric",
    deprecated: false
  )
end

defmodule Thorchain.Types.QueryObservedTx do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx, 1, type: Thorchain.Common.Tx, deprecated: false)
  field(:status, 2, type: :string)
  field(:out_hashes, 3, repeated: true, type: :string, json_name: "outHashes")
  field(:block_height, 4, type: :int64, json_name: "blockHeight", deprecated: false)
  field(:signers, 5, repeated: true, type: :string)
  field(:observed_pub_key, 6, type: :string, json_name: "observedPubKey", deprecated: false)
  field(:keysign_ms, 7, type: :int64, json_name: "keysignMs")
  field(:finalise_height, 8, type: :int64, json_name: "finaliseHeight", deprecated: false)
  field(:aggregator, 9, type: :string)
  field(:aggregator_target, 10, type: :string, json_name: "aggregatorTarget")

  field(:aggregator_target_limit, 11,
    type: :string,
    json_name: "aggregatorTargetLimit",
    deprecated: false
  )
end

defmodule Thorchain.Types.QueryObservedTxVoter do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx_id, 1, type: :string, json_name: "txId", deprecated: false)
  field(:tx, 2, type: Thorchain.Types.QueryObservedTx, deprecated: false)
  field(:height, 3, type: :int64, deprecated: false)
  field(:txs, 4, repeated: true, type: Thorchain.Types.QueryObservedTx, deprecated: false)
  field(:actions, 5, repeated: true, type: Thorchain.Types.TxOutItem, deprecated: false)

  field(:out_txs, 6,
    repeated: true,
    type: Thorchain.Common.Tx,
    json_name: "outTxs",
    deprecated: false
  )

  field(:finalised_height, 7, type: :int64, json_name: "finalisedHeight")
  field(:updated_vault, 8, type: :bool, json_name: "updatedVault")
  field(:reverted, 9, type: :bool)
  field(:outbound_height, 10, type: :int64, json_name: "outboundHeight")
end

defmodule Thorchain.Types.QueryTxVotersRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx_id, 1, type: :string, json_name: "txId")
  field(:height, 2, type: :string)
end

defmodule Thorchain.Types.PlannedOutTx do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:chain, 1, type: :string, deprecated: false)
  field(:to_address, 2, type: :string, json_name: "toAddress", deprecated: false)
  field(:coin, 3, type: Thorchain.Common.Coin, deprecated: false)
  field(:refund, 4, type: :bool, deprecated: false)
end

defmodule Thorchain.Types.InboundObservedStage do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:started, 1, type: :bool)
  field(:pre_confirmation_count, 2, type: :int64, json_name: "preConfirmationCount")
  field(:final_count, 3, type: :int64, json_name: "finalCount", deprecated: false)
  field(:completed, 4, type: :bool, deprecated: false)
end

defmodule Thorchain.Types.InboundConfirmationCountedStage do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:counting_start_height, 1, type: :int64, json_name: "countingStartHeight")
  field(:chain, 2, type: :string)
  field(:external_observed_height, 3, type: :int64, json_name: "externalObservedHeight")

  field(:external_confirmation_delay_height, 4,
    type: :int64,
    json_name: "externalConfirmationDelayHeight"
  )

  field(:remaining_confirmation_seconds, 5,
    type: :int64,
    json_name: "remainingConfirmationSeconds",
    deprecated: false
  )

  field(:completed, 6, type: :bool, deprecated: false)
end

defmodule Thorchain.Types.InboundFinalisedStage do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:completed, 1, type: :bool, deprecated: false)
end

defmodule Thorchain.Types.SwapStatus do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pending, 1, type: :bool, deprecated: false)
  field(:streaming, 2, type: Thorchain.Types.StreamingStatus)
end

defmodule Thorchain.Types.StreamingStatus do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:interval, 1, type: :int64, deprecated: false)
  field(:quantity, 2, type: :int64, deprecated: false)
  field(:count, 3, type: :int64, deprecated: false)
end

defmodule Thorchain.Types.SwapFinalisedStage do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:completed, 1, type: :bool, deprecated: false)
end

defmodule Thorchain.Types.OutboundDelayStage do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:remaining_delay_blocks, 1, type: :int64, json_name: "remainingDelayBlocks")
  field(:remaining_delay_seconds, 2, type: :int64, json_name: "remainingDelaySeconds")
  field(:completed, 3, type: :bool, deprecated: false)
end

defmodule Thorchain.Types.OutboundSignedStage do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:scheduled_outbound_height, 1, type: :int64, json_name: "scheduledOutboundHeight")

  field(:blocks_since_scheduled, 2,
    type: Thorchain.Types.ProtoInt64,
    json_name: "blocksSinceScheduled"
  )

  field(:completed, 3, type: :bool, deprecated: false)
end
