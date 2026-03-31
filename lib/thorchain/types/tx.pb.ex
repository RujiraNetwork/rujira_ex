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

  rpc(:Mimir, Thorchain.Types.MsgMimir, Thorchain.Types.MsgEmpty)

  rpc(:NetworkFee, Thorchain.Types.MsgNetworkFee, Thorchain.Types.MsgEmpty)

  rpc(:NodePauseChain, Thorchain.Types.MsgNodePauseChain, Thorchain.Types.MsgEmpty)

  rpc(:ObservedTxIn, Thorchain.Types.MsgObservedTxIn, Thorchain.Types.MsgEmpty)

  rpc(:ObservedTxOut, Thorchain.Types.MsgObservedTxOut, Thorchain.Types.MsgEmpty)

  rpc(:ThorSend, Thorchain.Types.MsgSend, Thorchain.Types.MsgEmpty)

  rpc(:SetIPAddress, Thorchain.Types.MsgSetIPAddress, Thorchain.Types.MsgEmpty)

  rpc(:SetNodeKeys, Thorchain.Types.MsgSetNodeKeys, Thorchain.Types.MsgEmpty)

  rpc(:Solvency, Thorchain.Types.MsgSolvency, Thorchain.Types.MsgEmpty)

  rpc(:TssKeysignFail, Thorchain.Types.MsgTssKeysignFail, Thorchain.Types.MsgEmpty)

  rpc(:TssPool, Thorchain.Types.MsgTssPool, Thorchain.Types.MsgEmpty)

  rpc(:SetVersion, Thorchain.Types.MsgSetVersion, Thorchain.Types.MsgEmpty)

  rpc(:ProposeUpgrade, Thorchain.Types.MsgProposeUpgrade, Thorchain.Types.MsgEmpty)

  rpc(:ApproveUpgrade, Thorchain.Types.MsgApproveUpgrade, Thorchain.Types.MsgEmpty)

  rpc(:RejectUpgrade, Thorchain.Types.MsgRejectUpgrade, Thorchain.Types.MsgEmpty)
end

defmodule Thorchain.Types.Msg.Stub do
  @moduledoc false

  use GRPC.Stub, service: Thorchain.Types.Msg.Service
end
