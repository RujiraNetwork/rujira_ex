defmodule Thorchain.Types.MsgEmpty do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Thorchain.Types.Msg.Service do
  @moduledoc false

  use GRPC.Service, name: "types.Msg", protoc_gen_elixir_version: "0.13.0"

  rpc(:Ban, Thorchain.Types.MsgBan, Thorchain.Types.MsgEmpty)

  rpc(:Deposit, Thorchain.Types.MsgDeposit, Thorchain.Types.MsgEmpty)

  rpc(:ErrataTx, Thorchain.Types.MsgErrataTx, Thorchain.Types.MsgEmpty)

  rpc(:ErrataTxQuorum, Thorchain.Types.MsgErrataTxQuorum, Thorchain.Types.MsgEmpty)

  rpc(:Mimir, Thorchain.Types.MsgMimir, Thorchain.Types.MsgEmpty)

  rpc(:NetworkFee, Thorchain.Types.MsgNetworkFee, Thorchain.Types.MsgEmpty)

  rpc(:NetworkFeeQuorum, Thorchain.Types.MsgNetworkFeeQuorum, Thorchain.Types.MsgEmpty)

  rpc(:NodePauseChain, Thorchain.Types.MsgNodePauseChain, Thorchain.Types.MsgEmpty)

  rpc(:ObservedTxIn, Thorchain.Types.MsgObservedTxIn, Thorchain.Types.MsgEmpty)

  rpc(:ObservedTxOut, Thorchain.Types.MsgObservedTxOut, Thorchain.Types.MsgEmpty)

  rpc(:ObservedTxQuorum, Thorchain.Types.MsgObservedTxQuorum, Thorchain.Types.MsgEmpty)

  rpc(:ThorSend, Thorchain.Types.MsgSend, Thorchain.Types.MsgEmpty)

  rpc(:SetIPAddress, Thorchain.Types.MsgSetIPAddress, Thorchain.Types.MsgEmpty)

  rpc(:SetNodeKeys, Thorchain.Types.MsgSetNodeKeys, Thorchain.Types.MsgEmpty)

  rpc(:Solvency, Thorchain.Types.MsgSolvency, Thorchain.Types.MsgEmpty)

  rpc(:SolvencyQuorum, Thorchain.Types.MsgSolvencyQuorum, Thorchain.Types.MsgEmpty)

  rpc(:TssKeysignFail, Thorchain.Types.MsgTssKeysignFail, Thorchain.Types.MsgEmpty)

  rpc(:TssPool, Thorchain.Types.MsgTssPool, Thorchain.Types.MsgEmpty)

  rpc(:SetVersion, Thorchain.Types.MsgSetVersion, Thorchain.Types.MsgEmpty)

  rpc(:ProposeUpgrade, Thorchain.Types.MsgProposeUpgrade, Thorchain.Types.MsgEmpty)

  rpc(:ApproveUpgrade, Thorchain.Types.MsgApproveUpgrade, Thorchain.Types.MsgEmpty)

  rpc(:RejectUpgrade, Thorchain.Types.MsgRejectUpgrade, Thorchain.Types.MsgEmpty)

  rpc(:PriceFeedQuorumBatch, Thorchain.Types.MsgPriceFeedQuorumBatch, Thorchain.Types.MsgEmpty)

  rpc(:StoreCode, Cosmwasm.Wasm.V1.MsgStoreCode, Cosmwasm.Wasm.V1.MsgStoreCodeResponse)

  rpc(
    :InstantiateContract,
    Cosmwasm.Wasm.V1.MsgInstantiateContract,
    Cosmwasm.Wasm.V1.MsgInstantiateContractResponse
  )

  rpc(
    :InstantiateContract2,
    Cosmwasm.Wasm.V1.MsgInstantiateContract2,
    Cosmwasm.Wasm.V1.MsgInstantiateContract2Response
  )

  rpc(
    :ExecuteContract,
    Cosmwasm.Wasm.V1.MsgExecuteContract,
    Cosmwasm.Wasm.V1.MsgExecuteContractResponse
  )

  rpc(
    :MigrateContract,
    Cosmwasm.Wasm.V1.MsgMigrateContract,
    Cosmwasm.Wasm.V1.MsgMigrateContractResponse
  )

  rpc(:SudoContract, Cosmwasm.Wasm.V1.MsgSudoContract, Cosmwasm.Wasm.V1.MsgSudoContractResponse)

  rpc(:UpdateAdmin, Cosmwasm.Wasm.V1.MsgUpdateAdmin, Cosmwasm.Wasm.V1.MsgUpdateAdminResponse)

  rpc(:ClearAdmin, Cosmwasm.Wasm.V1.MsgClearAdmin, Cosmwasm.Wasm.V1.MsgClearAdminResponse)
end

defmodule Thorchain.Types.Msg.Stub do
  @moduledoc false

  use GRPC.Stub, service: Thorchain.Types.Msg.Service
end
