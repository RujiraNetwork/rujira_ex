defmodule Thorchain.Common.Status do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:incomplete, 0)
  field(:done, 1)
  field(:reverted, 2)
end

defmodule Thorchain.Common.Asset do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:chain, 1, type: :string, deprecated: false)
  field(:symbol, 2, type: :string, deprecated: false)
  field(:ticker, 3, type: :string, deprecated: false)
  field(:synth, 4, type: :bool)
  field(:trade, 5, type: :bool)
  field(:secured, 6, type: :bool)
end

defmodule Thorchain.Common.Coin do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asset, 1, type: Thorchain.Common.Asset, deprecated: false)
  field(:amount, 2, type: :string, deprecated: false)
  field(:decimals, 3, type: :int64)
end

defmodule Thorchain.Common.PubKeySet do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:secp256k1, 1, type: :string, deprecated: false)
  field(:ed25519, 2, type: :string, deprecated: false)
end

defmodule Thorchain.Common.Tx do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:id, 1, type: :string, deprecated: false)
  field(:chain, 2, type: :string, deprecated: false)
  field(:from_address, 3, type: :string, json_name: "fromAddress", deprecated: false)
  field(:to_address, 4, type: :string, json_name: "toAddress", deprecated: false)
  field(:coins, 5, repeated: true, type: Thorchain.Common.Coin, deprecated: false)
  field(:gas, 6, repeated: true, type: Thorchain.Common.Coin, deprecated: false)
  field(:memo, 7, type: :string)
end

defmodule Thorchain.Common.Fee do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:coins, 1, repeated: true, type: Thorchain.Common.Coin, deprecated: false)
  field(:pool_deduct, 2, type: :string, json_name: "poolDeduct", deprecated: false)
end

defmodule Thorchain.Common.ProtoUint do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:value, 1, type: :string, deprecated: false)
end

defmodule Thorchain.Common.OutputRef do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx_hash, 1, type: :string, json_name: "txHash")
  field(:output_index, 2, type: :uint32, json_name: "outputIndex")
  field(:key_image, 3, type: :string, json_name: "keyImage")
  field(:spend_tx_hash, 4, type: :string, json_name: "spendTxHash")
end

defmodule Thorchain.Common.ObservedTx do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx, 1, type: Thorchain.Common.Tx, deprecated: false)
  field(:status, 2, type: Thorchain.Common.Status, enum: true)
  field(:out_hashes, 3, repeated: true, type: :string, json_name: "outHashes")
  field(:block_height, 4, type: :int64, json_name: "blockHeight")
  field(:signers, 5, repeated: true, type: :string)
  field(:observed_pub_key, 6, type: :string, json_name: "observedPubKey", deprecated: false)
  field(:keysign_ms, 7, type: :int64, json_name: "keysignMs")
  field(:finalise_height, 8, type: :int64, json_name: "finaliseHeight")
  field(:aggregator, 9, type: :string)
  field(:aggregator_target, 10, type: :string, json_name: "aggregatorTarget")

  field(:aggregator_target_limit, 11,
    type: :string,
    json_name: "aggregatorTargetLimit",
    deprecated: false
  )

  field(:spent_output_refs, 12,
    repeated: true,
    type: Thorchain.Common.OutputRef,
    json_name: "spentOutputRefs",
    deprecated: false
  )
end

defmodule Thorchain.Common.Attestation do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:PubKey, 1, type: :bytes)
  field(:Signature, 2, type: :bytes)
end

defmodule Thorchain.Common.AttestTx do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:obsTx, 1, type: Thorchain.Common.ObservedTx, deprecated: false)
  field(:attestation, 2, type: Thorchain.Common.Attestation)
  field(:inbound, 3, type: :bool)
  field(:allow_future_observation, 4, type: :bool, json_name: "allowFutureObservation")
end

defmodule Thorchain.Common.QuorumTx do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:obsTx, 1, type: Thorchain.Common.ObservedTx, deprecated: false)
  field(:attestations, 2, repeated: true, type: Thorchain.Common.Attestation)
  field(:inbound, 3, type: :bool)
  field(:allow_future_observation, 4, type: :bool, json_name: "allowFutureObservation")
end

defmodule Thorchain.Common.QuorumState do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:quoTxs, 1, repeated: true, type: Thorchain.Common.QuorumTx)
  field(:quoNetworkFees, 2, repeated: true, type: Thorchain.Common.QuorumNetworkFee)
  field(:quoSolvencies, 3, repeated: true, type: Thorchain.Common.QuorumSolvency)
  field(:quoErrataTxs, 4, repeated: true, type: Thorchain.Common.QuorumErrataTx)
  field(:quoPriceFeeds, 5, repeated: true, type: Thorchain.Common.QuorumPriceFeed)
end

defmodule Thorchain.Common.NetworkFee do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :int64)
  field(:chain, 2, type: :string, deprecated: false)
  field(:transaction_size, 3, type: :uint64, json_name: "transactionSize")
  field(:transaction_rate, 4, type: :uint64, json_name: "transactionRate")
end

defmodule Thorchain.Common.AttestNetworkFee do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:network_fee, 1, type: Thorchain.Common.NetworkFee, json_name: "networkFee")
  field(:attestation, 2, type: Thorchain.Common.Attestation)
end

defmodule Thorchain.Common.QuorumNetworkFee do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:network_fee, 1, type: Thorchain.Common.NetworkFee, json_name: "networkFee")
  field(:attestations, 2, repeated: true, type: Thorchain.Common.Attestation)
end

defmodule Thorchain.Common.Solvency do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:id, 1, type: :string, deprecated: false)
  field(:chain, 2, type: :string, deprecated: false)
  field(:pub_key, 3, type: :string, json_name: "pubKey", deprecated: false)
  field(:coins, 4, repeated: true, type: Thorchain.Common.Coin, deprecated: false)
  field(:height, 5, type: :int64)
end

defmodule Thorchain.Common.AttestSolvency do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:solvency, 1, type: Thorchain.Common.Solvency)
  field(:attestation, 2, type: Thorchain.Common.Attestation)
end

defmodule Thorchain.Common.QuorumSolvency do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:solvency, 1, type: Thorchain.Common.Solvency)
  field(:attestations, 2, repeated: true, type: Thorchain.Common.Attestation)
end

defmodule Thorchain.Common.ErrataTx do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:id, 1, type: :string, deprecated: false)
  field(:chain, 2, type: :string, deprecated: false)
end

defmodule Thorchain.Common.AttestErrataTx do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:errata_tx, 1, type: Thorchain.Common.ErrataTx, json_name: "errataTx")
  field(:attestation, 2, type: Thorchain.Common.Attestation)
end

defmodule Thorchain.Common.QuorumErrataTx do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:errata_tx, 1, type: Thorchain.Common.ErrataTx, json_name: "errataTx")
  field(:attestations, 2, repeated: true, type: Thorchain.Common.Attestation)
end

defmodule Thorchain.Common.PriceFeed do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:version, 1, type: :bytes)
  field(:time, 2, type: :int64)
  field(:rates, 3, repeated: true, type: Thorchain.Common.OraclePrice)
end

defmodule Thorchain.Common.AttestPriceFeed do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:price_feed, 1, type: Thorchain.Common.PriceFeed, json_name: "priceFeed")
  field(:attestation, 2, type: Thorchain.Common.Attestation)
end

defmodule Thorchain.Common.QuorumPriceFeed do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:price_feed, 1, type: Thorchain.Common.PriceFeed, json_name: "priceFeed")
  field(:attestations, 2, repeated: true, type: Thorchain.Common.Attestation)
end

defmodule Thorchain.Common.QuorumPriceFeedBatch do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:quorum_price_feeds, 1,
    repeated: true,
    type: Thorchain.Common.QuorumPriceFeed,
    json_name: "quorumPriceFeeds"
  )
end

defmodule Thorchain.Common.OraclePrice do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:amount, 1, type: :uint64)
  field(:decimals, 2, type: :uint32)
end

defmodule Thorchain.Common.AttestationBatch do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:attest_txs, 1, repeated: true, type: Thorchain.Common.AttestTx, json_name: "attestTxs")

  field(:attest_network_fees, 2,
    repeated: true,
    type: Thorchain.Common.AttestNetworkFee,
    json_name: "attestNetworkFees"
  )

  field(:attest_solvencies, 3,
    repeated: true,
    type: Thorchain.Common.AttestSolvency,
    json_name: "attestSolvencies"
  )

  field(:attest_errata_txs, 4,
    repeated: true,
    type: Thorchain.Common.AttestErrataTx,
    json_name: "attestErrataTxs"
  )

  field(:attest_price_feeds, 5,
    repeated: true,
    type: Thorchain.Common.AttestPriceFeed,
    json_name: "attestPriceFeeds"
  )
end
