defmodule Thorchain.Types.Query.Service do
  @moduledoc false

  use GRPC.Service, name: "types.Query", protoc_gen_elixir_version: "0.13.0"

  rpc(:Account, Thorchain.Types.QueryAccountRequest, Thorchain.Types.QueryAccountResponse)

  rpc(:Balances, Thorchain.Types.QueryBalancesRequest, Thorchain.Types.QueryBalancesResponse)

  rpc(:Export, Thorchain.Types.QueryExportRequest, Thorchain.Types.QueryExportResponse)

  rpc(:Pool, Thorchain.Types.QueryPoolRequest, Thorchain.Types.QueryPoolResponse)

  rpc(:Pools, Thorchain.Types.QueryPoolsRequest, Thorchain.Types.QueryPoolsResponse)

  rpc(
    :DerivedPool,
    Thorchain.Types.QueryDerivedPoolRequest,
    Thorchain.Types.QueryDerivedPoolResponse
  )

  rpc(
    :DerivedPools,
    Thorchain.Types.QueryDerivedPoolsRequest,
    Thorchain.Types.QueryDerivedPoolsResponse
  )

  rpc(
    :LiquidityProvider,
    Thorchain.Types.QueryLiquidityProviderRequest,
    Thorchain.Types.QueryLiquidityProviderResponse
  )

  rpc(
    :LiquidityProviders,
    Thorchain.Types.QueryLiquidityProvidersRequest,
    Thorchain.Types.QueryLiquidityProvidersResponse
  )

  rpc(:Saver, Thorchain.Types.QuerySaverRequest, Thorchain.Types.QuerySaverResponse)

  rpc(:Savers, Thorchain.Types.QuerySaversRequest, Thorchain.Types.QuerySaversResponse)

  rpc(:TradeUnit, Thorchain.Types.QueryTradeUnitRequest, Thorchain.Types.QueryTradeUnitResponse)

  rpc(
    :TradeUnits,
    Thorchain.Types.QueryTradeUnitsRequest,
    Thorchain.Types.QueryTradeUnitsResponse
  )

  rpc(
    :TradeAccount,
    Thorchain.Types.QueryTradeAccountRequest,
    Thorchain.Types.QueryTradeAccountsResponse
  )

  rpc(
    :TradeAccounts,
    Thorchain.Types.QueryTradeAccountsRequest,
    Thorchain.Types.QueryTradeAccountsResponse
  )

  rpc(
    :SecuredAsset,
    Thorchain.Types.QuerySecuredAssetRequest,
    Thorchain.Types.QuerySecuredAssetResponse
  )

  rpc(
    :SecuredAssets,
    Thorchain.Types.QuerySecuredAssetsRequest,
    Thorchain.Types.QuerySecuredAssetsResponse
  )

  rpc(:Node, Thorchain.Types.QueryNodeRequest, Thorchain.Types.QueryNodeResponse)

  rpc(:Nodes, Thorchain.Types.QueryNodesRequest, Thorchain.Types.QueryNodesResponse)

  rpc(:PoolSlip, Thorchain.Types.QueryPoolSlipRequest, Thorchain.Types.QueryPoolSlipsResponse)

  rpc(:PoolSlips, Thorchain.Types.QueryPoolSlipsRequest, Thorchain.Types.QueryPoolSlipsResponse)

  rpc(
    :OutboundFee,
    Thorchain.Types.QueryOutboundFeeRequest,
    Thorchain.Types.QueryOutboundFeesResponse
  )

  rpc(
    :OutboundFees,
    Thorchain.Types.QueryOutboundFeesRequest,
    Thorchain.Types.QueryOutboundFeesResponse
  )

  rpc(
    :StreamingSwap,
    Thorchain.Types.QueryStreamingSwapRequest,
    Thorchain.Types.QueryStreamingSwapResponse
  )

  rpc(
    :StreamingSwaps,
    Thorchain.Types.QueryStreamingSwapsRequest,
    Thorchain.Types.QueryStreamingSwapsResponse
  )

  rpc(:Ban, Thorchain.Types.QueryBanRequest, Thorchain.Types.BanVoter)

  rpc(:Ragnarok, Thorchain.Types.QueryRagnarokRequest, Thorchain.Types.QueryRagnarokResponse)

  rpc(:RunePool, Thorchain.Types.QueryRunePoolRequest, Thorchain.Types.QueryRunePoolResponse)

  rpc(
    :RuneProvider,
    Thorchain.Types.QueryRuneProviderRequest,
    Thorchain.Types.QueryRuneProviderResponse
  )

  rpc(
    :RuneProviders,
    Thorchain.Types.QueryRuneProvidersRequest,
    Thorchain.Types.QueryRuneProvidersResponse
  )

  rpc(
    :MimirValues,
    Thorchain.Types.QueryMimirValuesRequest,
    Thorchain.Types.QueryMimirValuesResponse
  )

  rpc(
    :MimirWithKey,
    Thorchain.Types.QueryMimirWithKeyRequest,
    Thorchain.Types.QueryMimirWithKeyResponse
  )

  rpc(
    :MimirAdminValues,
    Thorchain.Types.QueryMimirAdminValuesRequest,
    Thorchain.Types.QueryMimirAdminValuesResponse
  )

  rpc(
    :MimirNodesAllValues,
    Thorchain.Types.QueryMimirNodesAllValuesRequest,
    Thorchain.Types.QueryMimirNodesAllValuesResponse
  )

  rpc(
    :MimirNodesValues,
    Thorchain.Types.QueryMimirNodesValuesRequest,
    Thorchain.Types.QueryMimirNodesValuesResponse
  )

  rpc(
    :MimirNodeValues,
    Thorchain.Types.QueryMimirNodeValuesRequest,
    Thorchain.Types.QueryMimirNodeValuesResponse
  )

  rpc(
    :InboundAddresses,
    Thorchain.Types.QueryInboundAddressesRequest,
    Thorchain.Types.QueryInboundAddressesResponse
  )

  rpc(:Version, Thorchain.Types.QueryVersionRequest, Thorchain.Types.QueryVersionResponse)

  rpc(:Thorname, Thorchain.Types.QueryThornameRequest, Thorchain.Types.QueryThornameResponse)

  rpc(:Invariant, Thorchain.Types.QueryInvariantRequest, Thorchain.Types.QueryInvariantResponse)

  rpc(
    :Invariants,
    Thorchain.Types.QueryInvariantsRequest,
    Thorchain.Types.QueryInvariantsResponse
  )

  rpc(:Network, Thorchain.Types.QueryNetworkRequest, Thorchain.Types.QueryNetworkResponse)

  rpc(
    :BalanceModule,
    Thorchain.Types.QueryBalanceModuleRequest,
    Thorchain.Types.QueryBalanceModuleResponse
  )

  rpc(:QuoteSwap, Thorchain.Types.QueryQuoteSwapRequest, Thorchain.Types.QueryQuoteSwapResponse)

  rpc(
    :QuoteSaverDeposit,
    Thorchain.Types.QueryQuoteSaverDepositRequest,
    Thorchain.Types.QueryQuoteSaverDepositResponse
  )

  rpc(
    :QuoteSaverWithdraw,
    Thorchain.Types.QueryQuoteSaverWithdrawRequest,
    Thorchain.Types.QueryQuoteSaverWithdrawResponse
  )

  rpc(
    :ConstantValues,
    Thorchain.Types.QueryConstantValuesRequest,
    Thorchain.Types.QueryConstantValuesResponse
  )

  rpc(:SwapQueue, Thorchain.Types.QuerySwapQueueRequest, Thorchain.Types.QuerySwapQueueResponse)

  rpc(
    :LastBlocks,
    Thorchain.Types.QueryLastBlocksRequest,
    Thorchain.Types.QueryLastBlocksResponse
  )

  rpc(
    :ChainsLastBlock,
    Thorchain.Types.QueryChainsLastBlockRequest,
    Thorchain.Types.QueryLastBlocksResponse
  )

  rpc(:Vault, Thorchain.Types.QueryVaultRequest, Thorchain.Types.QueryVaultResponse)

  rpc(
    :AsgardVaults,
    Thorchain.Types.QueryAsgardVaultsRequest,
    Thorchain.Types.QueryAsgardVaultsResponse
  )

  rpc(
    :VaultsPubkeys,
    Thorchain.Types.QueryVaultsPubkeysRequest,
    Thorchain.Types.QueryVaultsPubkeysResponse
  )

  rpc(:TxStages, Thorchain.Types.QueryTxStagesRequest, Thorchain.Types.QueryTxStagesResponse)

  rpc(:TxStatus, Thorchain.Types.QueryTxStatusRequest, Thorchain.Types.QueryTxStatusResponse)

  rpc(:Tx, Thorchain.Types.QueryTxRequest, Thorchain.Types.QueryTxResponse)

  rpc(:TxVoters, Thorchain.Types.QueryTxVotersRequest, Thorchain.Types.QueryObservedTxVoter)

  rpc(:TxVotersOld, Thorchain.Types.QueryTxVotersRequest, Thorchain.Types.QueryObservedTxVoter)

  rpc(:Clout, Thorchain.Types.QuerySwapperCloutRequest, Thorchain.Types.SwapperClout)

  rpc(:Queue, Thorchain.Types.QueryQueueRequest, Thorchain.Types.QueryQueueResponse)

  rpc(
    :ScheduledOutbound,
    Thorchain.Types.QueryScheduledOutboundRequest,
    Thorchain.Types.QueryOutboundResponse
  )

  rpc(
    :PendingOutbound,
    Thorchain.Types.QueryPendingOutboundRequest,
    Thorchain.Types.QueryOutboundResponse
  )

  rpc(:Block, Thorchain.Types.QueryBlockRequest, Thorchain.Types.QueryBlockResponse)

  rpc(
    :TssKeygenMetric,
    Thorchain.Types.QueryTssKeygenMetricRequest,
    Thorchain.Types.QueryTssKeygenMetricResponse
  )

  rpc(:TssMetric, Thorchain.Types.QueryTssMetricRequest, Thorchain.Types.QueryTssMetricResponse)

  rpc(:Keysign, Thorchain.Types.QueryKeysignRequest, Thorchain.Types.QueryKeysignResponse)

  rpc(
    :KeysignPubkey,
    Thorchain.Types.QueryKeysignPubkeyRequest,
    Thorchain.Types.QueryKeysignResponse
  )

  rpc(:Keygen, Thorchain.Types.QueryKeygenRequest, Thorchain.Types.QueryKeygenResponse)

  rpc(
    :UpgradeProposals,
    Thorchain.Types.QueryUpgradeProposalsRequest,
    Thorchain.Types.QueryUpgradeProposalsResponse
  )

  rpc(
    :UpgradeProposal,
    Thorchain.Types.QueryUpgradeProposalRequest,
    Thorchain.Types.QueryUpgradeProposalResponse
  )

  rpc(
    :UpgradeVotes,
    Thorchain.Types.QueryUpgradeVotesRequest,
    Thorchain.Types.QueryUpgradeVotesResponse
  )

  rpc(
    :OraclePrice,
    Thorchain.Types.QueryOraclePriceRequest,
    Thorchain.Types.QueryOraclePriceResponse
  )

  rpc(
    :ContractInfos,
    Thorchain.Types.QueryContractInfosRequest,
    Thorchain.Types.QueryContractInfosResponse
  )

  rpc(
    :ContractInfo,
    Thorchain.Types.QueryContractInfoRequest,
    Thorchain.Types.QueryContractInfoResponse
  )
end

defmodule Thorchain.Types.Query.Stub do
  @moduledoc false

  use GRPC.Stub, service: Thorchain.Types.Query.Service
end
