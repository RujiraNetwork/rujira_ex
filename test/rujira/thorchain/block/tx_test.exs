defmodule Rujira.Thorchain.Block.TxTest do
  @moduledoc """
  `Block.new/1` is pure, so this case needs neither the cache nor a node: every
  coin in the fixtures resolves without reading denom metadata.

  The fixtures in `test/fixtures/block_txs.json` are real mainnet transactions,
  one per message type the node rendered, trimmed of attestations and all but
  one signature. The message types mainnet did not produce in that window are
  built inline here from the shape thornode and wasmd render.
  """
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias Rujira.Assets.Asset
  alias Rujira.Coin
  alias Rujira.Thorchain.Block
  alias Rujira.Thorchain.Block.Messages.ClearAdmin
  alias Rujira.Thorchain.Block.Messages.Deposit
  alias Rujira.Thorchain.Block.Messages.ExecuteContract
  alias Rujira.Thorchain.Block.Messages.InstantiateContract
  alias Rujira.Thorchain.Block.Messages.InstantiateContract2
  alias Rujira.Thorchain.Block.Messages.Message
  alias Rujira.Thorchain.Block.Messages.MigrateContract
  alias Rujira.Thorchain.Block.Messages.ObservedTx
  alias Rujira.Thorchain.Block.Messages.ObservedTxIn
  alias Rujira.Thorchain.Block.Messages.ObservedTxOut
  alias Rujira.Thorchain.Block.Messages.ObservedTxQuorum
  alias Rujira.Thorchain.Block.Messages.Send
  alias Rujira.Thorchain.Block.Messages.StoreCode
  alias Rujira.Thorchain.Block.Messages.SudoContract
  alias Rujira.Thorchain.Block.Messages.UpdateAdmin
  alias Rujira.Thorchain.Block.Observation
  alias Thorchain.Types.BlockTxResult
  alias Thorchain.Types.QueryBlockResponse
  alias Thorchain.Types.BlockResponseHeader
  alias Thorchain.Types.QueryBlockTx

  @fixtures "test/fixtures/block_txs.json" |> File.read!() |> JSON.decode!()

  describe "envelopes" do
    test "a signed transaction carries its hash, code, memo and messages" do
      assert [tx] = txs(fixture("/types.MsgDeposit"))

      assert %{
               idx: 0,
               hash: "00000000168BFF0AC22B20464475B0AC6A28B405E80C49A92392DDB6AA2E19B0",
               code: 0,
               memo: nil,
               messages: [%Deposit{}]
             } = tx
    end

    test "the transaction memo is the body's, nil when empty" do
      assert [%{memo: memo}] = txs(fixture("/types.MsgDeposit:failed"))

      assert memo ==
               "REFERENCE:BTC.BTC:=:e:sthor1v8ppstuf6e3x0r4glqc68d5jqcs2tf38v3kkv6:3091141304/0/20:sto/uws:0/1"

      assert [%{memo: nil}] = txs(fixture("/types.MsgDeposit"))
    end

    test "an injected transaction has no body, so no memo, and its messages still parse" do
      assert [%{memo: nil, messages: [%ObservedTxQuorum{}]}] =
               txs(fixture("/types.MsgObservedTxQuorum:inbound"))
    end

    test "idx counts transactions in block order and matches the events' tx_idx" do
      assert [%{idx: 0}, %{idx: 1}, %{idx: 2}] =
               txs([
                 fixture("/types.MsgDeposit"),
                 fixture("/types.MsgSend"),
                 fixture("/types.MsgDeposit:failed")
               ])
    end

    test "a failed transaction keeps its code" do
      assert [%{code: 99}] = txs(fixture("/types.MsgDeposit:failed"))
      assert [%{code: 5}] = txs(fixture("/cosmwasm.wasm.v1.MsgExecuteContract:failed"))
    end

    test "a transaction with no result has a nil code, never a 0 that reads as success" do
      assert {:ok, %Block{txs: [%{code: nil, hash: "HASH"}]}} =
               Block.new(response([%QueryBlockTx{hash: "HASH", tx: "", result: nil}]))
    end

    test "every message of a multi-message transaction is parsed, in order" do
      assert [
               %{
                 messages: [%ExecuteContract{contract: first}, %ExecuteContract{contract: second}]
               }
             ] =
               txs(fixture("/cosmwasm.wasm.v1.MsgExecuteContract"))

      assert first == "thor1s4jpxtz0jsh6elyqcdujd303ptefz53gknmcp437rm9ykxnfhysqrm5hze"
      assert second == "thor1dwsnlqw3lfhamc5dz3r57hlsppx3a2n2d7kppccxfdhfazjh06rs5077sz"
    end
  end

  describe "undecodable transactions" do
    test "the transaction keeps its hash and code with no messages, and warns" do
      response = response([%QueryBlockTx{hash: "HASH", tx: "{not json", result: result(0)}])

      log = capture_log(fn -> assert {:ok, %Block{}} = Block.new(response) end)

      assert {:ok, %Block{txs: [%{hash: "HASH", code: 0, memo: nil, messages: []}]}} =
               Block.new(response)

      assert log =~ "undecodable tx"
      assert log =~ "height=7"
      assert log =~ "tx_idx=0"
    end

    test "a transaction the node sent no JSON for is not a failure and is not warned about" do
      response = response([%QueryBlockTx{hash: "HASH", tx: "", result: result(0)}])

      log = capture_log(fn -> assert {:ok, %Block{}} = Block.new(response) end)

      assert {:ok, %Block{txs: [%{hash: "HASH", messages: []}]}} = Block.new(response)
      refute log =~ "undecodable tx"
    end
  end

  describe "thorchain messages" do
    test "a deposit carries its coins by asset id, its memo and its signer" do
      assert [%{messages: [%Deposit{coins: coins, memo: memo, signer: signer}]}] =
               txs(fixture("/types.MsgDeposit"))

      assert [%Coin{asset: %Asset{id: "BTC~BTC"}, amount: 2_758_084}] = coins
      assert memo =~ "=:ETH~USDT-0XDAC17F958D2EE523A2206206994597C13D831EC7:"
      assert signer == "thor166n4w5039meulfa3p6ydg60ve6ueac7tlt0jws"
    end

    test "a thorchain send carries its coins by bank denom" do
      assert [%{messages: [%Send{from: from, to: to, coins: coins}]}] =
               txs(fixture("/types.MsgSend"))

      assert from == "thor1t60f02r8jvzjrhtnjgfj4ne6rs5wjnejwmj7fh"
      assert to == "thor166n4w5039meulfa3p6ydg60ve6ueac7tlt0jws"
      assert [%Coin{asset: %Asset{id: "THOR.RUNE"}, amount: 807_428_200_000}] = coins
    end

    test "a cosmos bank send parses into the same Send struct" do
      msg = %{
        "@type" => "/cosmos.bank.v1beta1.MsgSend",
        "from_address" => "thor1t60f02r8jvzjrhtnjgfj4ne6rs5wjnejwmj7fh",
        "to_address" => "thor166n4w5039meulfa3p6ydg60ve6ueac7tlt0jws",
        "amount" => [%{"denom" => "rune", "amount" => "100"}]
      }

      assert [
               %{
                 messages: [%Send{from: "thor1t60f02r8jvzjrhtnjgfj4ne6rs5wjnejwmj7fh"} = send]
               }
             ] =
               txs(signed([msg]))

      assert [%Coin{asset: %Asset{id: "THOR.RUNE"}, amount: 100}] = send.coins
    end

    test "a send with a malformed coin becomes a generic message, not a raise" do
      msg = %{
        "@type" => "/types.MsgSend",
        "from_address" => "thor1t60f02r8jvzjrhtnjgfj4ne6rs5wjnejwmj7fh",
        "to_address" => "thor166n4w5039meulfa3p6ydg60ve6ueac7tlt0jws",
        "amount" => [%{"denom" => nil, "amount" => "5"}]
      }

      log = capture_log(fn -> assert [_] = txs(signed([msg])) end)

      assert [%{messages: [%Message{type_url: "/types.MsgSend", data: ^msg}]}] =
               txs(signed([msg]))

      assert log =~ "unparsed message"
      assert log =~ ":invalid_attrs"
    end

    test "a send with an empty string amount becomes a generic message, not a raise" do
      msg = %{
        "@type" => "/types.MsgSend",
        "from_address" => "thor1t60f02r8jvzjrhtnjgfj4ne6rs5wjnejwmj7fh",
        "to_address" => "thor166n4w5039meulfa3p6ydg60ve6ueac7tlt0jws",
        "amount" => [%{"denom" => "rune", "amount" => ""}]
      }

      log = capture_log(fn -> assert [_] = txs(signed([msg])) end)

      assert [%{messages: [%Message{type_url: "/types.MsgSend", data: ^msg}]}] =
               txs(signed([msg]))

      assert log =~ "unparsed message"
      assert log =~ ":invalid_attrs"
    end
  end

  describe "wasm messages" do
    test "an execute carries its decoded msg and funds" do
      assert [%{messages: [%ExecuteContract{} = execute]}] =
               txs(fixture("/cosmwasm.wasm.v1.MsgExecuteContract:failed"))

      assert execute.sender == "thor1kr08pw3rtng29tj63jgwx22vp4e447mhrcvxyd"
      assert %{"swap" => %{"affiliate_code" => "arb"}} = execute.msg

      assert [%Coin{asset: %Asset{id: "ETH-USDC-0XA0B86991C6218B36C1D19D4A2E9EB0CE3606EB48"}}] =
               execute.funds
    end

    test "a base64 msg decodes to the same map as a rendered one" do
      msg = %{
        "@type" => "/cosmwasm.wasm.v1.MsgExecuteContract",
        "sender" => "thor1sender",
        "contract" => "thor1contract",
        "msg" => Base.encode64(~s({"arb":{}})),
        "funds" => []
      }

      assert [%{messages: [%ExecuteContract{msg: %{"arb" => %{}}}]}] = txs(signed([msg]))
    end

    test "an instantiate carries its integer code_id, its admin and its payload" do
      msg = %{
        "@type" => "/cosmwasm.wasm.v1.MsgInstantiateContract",
        "sender" => "thor1sender",
        "admin" => "",
        "code_id" => "42",
        "label" => "fin-pair",
        "msg" => %{"owner" => "thor1owner"},
        "funds" => [%{"denom" => "rune", "amount" => "1"}]
      }

      assert [%{messages: [%InstantiateContract{} = instantiate]}] = txs(signed([msg]))
      assert instantiate.code_id == 42
      assert instantiate.admin == nil
      assert instantiate.label == "fin-pair"
      assert instantiate.msg == %{"owner" => "thor1owner"}
      assert [%Coin{amount: 1}] = instantiate.funds
    end

    test "an instantiate2 adds the salt and the fix_msg flag" do
      msg = %{
        "@type" => "/cosmwasm.wasm.v1.MsgInstantiateContract2",
        "sender" => "thor1sender",
        "admin" => "thor1admin",
        "code_id" => "42",
        "label" => "fin-pair",
        "msg" => %{},
        "funds" => [],
        "salt" => "c2FsdA==",
        "fix_msg" => true
      }

      assert [%{messages: [%InstantiateContract2{} = instantiate]}] = txs(signed([msg]))
      assert instantiate.admin == "thor1admin"
      assert instantiate.salt == "c2FsdA=="
      assert instantiate.fix_msg == true
    end

    test "a migrate names the code it migrates to" do
      msg = %{
        "@type" => "/cosmwasm.wasm.v1.MsgMigrateContract",
        "sender" => "thor1sender",
        "contract" => "thor1contract",
        "code_id" => "7",
        "msg" => %{"migrate" => %{}}
      }

      assert [%{messages: [%MigrateContract{code_id: 7, msg: %{"migrate" => %{}}}]}] =
               txs(signed([msg]))
    end

    test "a store_code keeps the uploader and the permission, never the wasm binary" do
      msg = %{
        "@type" => "/cosmwasm.wasm.v1.MsgStoreCode",
        "sender" => "thor1sender",
        "wasm_byte_code" => Base.encode64(:binary.copy("wasm", 1_000)),
        "instantiate_permission" => %{"permission" => "Everybody", "addresses" => []}
      }

      assert [%{messages: [%StoreCode{} = store]}] = txs(signed([msg]))
      assert store.sender == "thor1sender"
      assert store.instantiate_permission == %{"permission" => "Everybody", "addresses" => []}
      refute Map.has_key?(Map.from_struct(store), :wasm_byte_code)
    end

    test "the admin messages and sudo carry their addresses" do
      update = %{
        "@type" => "/cosmwasm.wasm.v1.MsgUpdateAdmin",
        "sender" => "thor1sender",
        "new_admin" => "thor1new",
        "contract" => "thor1contract"
      }

      clear = %{
        "@type" => "/cosmwasm.wasm.v1.MsgClearAdmin",
        "sender" => "thor1sender",
        "contract" => "thor1contract"
      }

      sudo = %{
        "@type" => "/cosmwasm.wasm.v1.MsgSudoContract",
        "authority" => "thor1gov",
        "contract" => "thor1contract",
        "msg" => %{"halt" => %{}}
      }

      assert [%{messages: messages}] = txs(signed([update, clear, sudo]))

      assert [
               %UpdateAdmin{new_admin: "thor1new", contract: "thor1contract"},
               %ClearAdmin{sender: "thor1sender", contract: "thor1contract"},
               %SudoContract{authority: "thor1gov", msg: %{"halt" => %{}}}
             ] = messages
    end
  end

  describe "observation messages" do
    test "a quorum carries the observed tx, its direction and how many attested" do
      assert [%{messages: [%ObservedTxQuorum{} = quorum]}] =
               txs(fixture("/types.MsgObservedTxQuorum:inbound"))

      assert quorum.inbound == true
      assert quorum.attestations == 2
      assert quorum.signer == "thor1zxhfu0qmmq6gmgq4sgz0xgq69h0nhqx5yrseu5"

      assert %ObservedTx{
               id: "C371A9ED5AF3DBEAD6246A7F5CDC6D8FF15296022EAB1A300EAEBC9BA47D6DD4",
               chain: "ETH",
               from: "0x793129bc90f958069429f43f42df2f8365549f36",
               to: "0x0db14a0288f4637f60b46690f1971b756c58a47e",
               status: :incomplete,
               out_hashes: [],
               block_height: 26_053_603,
               finalise_height: 26_053_603,
               aggregator: nil,
               aggregator_target: nil,
               aggregator_target_limit: nil
             } = quorum.tx

      assert [%Coin{asset: %Asset{id: "ETH.ETH"}, amount: 156_962_078}] = quorum.tx.coins
      assert [%Coin{asset: %Asset{id: "ETH.ETH"}, amount: 4260}] = quorum.tx.gas

      assert quorum.tx.memo =~
               "=:b:bc1p2e3l03h5n0tkskg9hh2869wp0m7tjmlz7mvl8lk7zu34uzufhz0qlgfk2u"

      assert quorum.tx.observed_pub_key =~ "thorpub1addwnpepq"
    end

    test "an observed tx with an aggregator swap and out-hashes carries them" do
      msg =
        update_in(observed_tx_msg("/types.MsgObservedTxIn", 1), ["txs", Access.at!(0)], fn obs ->
          Map.merge(obs, %{
            "status" => "done",
            "out_hashes" => ["ABC123"],
            "aggregator" => "0xaggregator",
            "aggregator_target" => "0xtarget",
            "aggregator_target_limit" => "12345"
          })
        end)

      assert [%{messages: [%ObservedTxIn{txs: [tx]}]}] = txs(signed([msg]))

      assert %ObservedTx{
               status: :done,
               out_hashes: ["ABC123"],
               aggregator: "0xaggregator",
               aggregator_target: "0xtarget",
               aggregator_target_limit: 12_345
             } = tx
    end

    test "an outbound quorum is not inbound" do
      assert [%{messages: [%ObservedTxQuorum{inbound: false, tx: %ObservedTx{chain: "BTC"}}]}] =
               txs(fixture("/types.MsgObservedTxQuorum:outbound"))
    end

    test "no attestation signature is kept" do
      assert [%{messages: [%ObservedTxQuorum{} = quorum]}] =
               txs(fixture("/types.MsgObservedTxQuorum:outbound"))

      refute quorum |> Map.from_struct() |> Map.has_key?(:attestations_signatures)
      refute inspect(quorum) =~ "Signature"
      refute inspect(quorum) =~ "PubKey"
    end

    test "a per-validator observation message carries every tx it observed" do
      assert [%{messages: [%ObservedTxIn{txs: [one, two], signer: "thor1node"}]}] =
               txs(signed([observed_tx_msg("/types.MsgObservedTxIn", 2)]))

      assert %ObservedTx{id: "TX0", chain: "BTC", block_height: 100, finalise_height: 101} = one
      assert %ObservedTx{id: "TX1"} = two
      assert [%Coin{asset: %Asset{id: "BTC.BTC"}, amount: 1000}] = one.coins
    end

    test "an outbound observation message parses the same way" do
      assert [%{messages: [%ObservedTxOut{txs: [%ObservedTx{id: "TX0"}]}]}] =
               txs(signed([observed_tx_msg("/types.MsgObservedTxOut", 1)]))
    end
  end

  describe "generic messages" do
    test "a type with no struct keeps its type_url and the map the node sent" do
      assert [%{messages: [%Message{type_url: "/types.MsgSolvencyQuorum", data: data}]}] =
               txs(fixture("/types.MsgSolvencyQuorum"))

      assert %{"@type" => "/types.MsgSolvencyQuorum", "quoSolvency" => %{}} = data
    end

    test "every quorum type without a struct of its own stays generic" do
      for type <- [
            "/types.MsgPriceFeedQuorumBatch",
            "/types.MsgNetworkFeeQuorum",
            "/types.MsgTssKeysignFail"
          ] do
        assert [%{messages: [%Message{type_url: ^type}]}] = txs(fixture(type))
      end
    end

    test "a known type that does not parse becomes generic, with a warning" do
      msg = %{"@type" => "/types.MsgDeposit", "coins" => "not a list", "signer" => "thor1abc"}

      log = capture_log(fn -> assert [_] = txs(signed([msg])) end)

      assert [%{messages: [%Message{type_url: "/types.MsgDeposit", data: ^msg}]}] =
               txs(signed([msg]))

      assert log =~ "unparsed message"
      assert log =~ "height=7"
      assert log =~ "tx_idx=0"
      assert log =~ "msg_idx=0"
      assert log =~ "type=/types.MsgDeposit"
      assert log =~ ":invalid_attrs"
    end

    test "a message with no @type is generic with a nil type_url, and the block survives" do
      assert [%{messages: [%Message{type_url: nil, data: %{"foo" => "bar"}}]}] =
               txs(signed([%{"foo" => "bar"}]))
    end

    test "a message that is not a map at all does not fail the block, and keeps its raw value" do
      log =
        capture_log(fn ->
          assert [%{messages: [%Message{type_url: nil, data: %{"value" => "nonsense"}}]}] =
                   txs(signed(["nonsense"]))
        end)

      assert log =~ "unparsed message"
      assert log =~ ":invalid_message"
    end
  end

  describe "observed_txs/1" do
    test "every observation of the block, in order, with its direction and tx_idx" do
      assert {:ok, block} =
               Block.new(
                 response([
                   block_tx(fixture("/types.MsgObservedTxQuorum:inbound")),
                   block_tx(signed([observed_tx_msg("/types.MsgObservedTxOut", 2)])),
                   block_tx(fixture("/types.MsgDeposit"))
                 ])
               )

      assert [one, two, three] = Block.observed_txs(block)

      assert %Observation{tx_idx: 0, inbound: true, tx: %ObservedTx{chain: "ETH"}} = one
      assert %Observation{tx_idx: 1, inbound: false, tx: %ObservedTx{id: "TX0"}} = two
      assert %Observation{tx_idx: 1, inbound: false, tx: %ObservedTx{id: "TX1"}} = three
    end

    test "a failed transaction's observations are not observations the chain made" do
      failed = %{block_tx(fixture("/types.MsgObservedTxQuorum:inbound")) | result: result(6)}

      assert {:ok, block} = Block.new(response([failed]))
      assert Block.observed_txs(block) == []
    end

    test "a transaction with no result is not read as successful" do
      tx = %{block_tx(fixture("/types.MsgObservedTxQuorum:inbound")) | result: nil}

      assert {:ok, block} = Block.new(response([tx]))
      assert Block.observed_txs(block) == []
    end

    test "a block that observed nothing has no observations" do
      assert {:ok, block} = Block.new(response([block_tx(fixture("/types.MsgDeposit"))]))
      assert Block.observed_txs(block) == []
    end

    test "the facade delegates" do
      assert {:ok, block} =
               Block.new(response([block_tx(fixture("/types.MsgObservedTxQuorum:outbound"))]))

      assert [%Observation{inbound: false}] = Rujira.Thorchain.block_observed_txs(block)
    end
  end

  # --- Fixtures ---

  defp fixture(name), do: Map.fetch!(@fixtures, name)

  # A signed envelope around messages mainnet did not produce in the sampled window.
  defp signed(messages) do
    %{
      "hash" => "SYNTHETIC",
      "code" => 0,
      "tx" => %{"body" => %{"messages" => messages, "memo" => ""}}
    }
  end

  defp observed_tx_msg(type, count) do
    %{
      "@type" => type,
      "signer" => "thor1node",
      "txs" =>
        Enum.map(0..(count - 1), fn i ->
          %{
            "tx" => %{
              "id" => "TX#{i}",
              "chain" => "BTC",
              "from_address" => "bc1qfrom",
              "to_address" => "bc1qto",
              "coins" => [%{"asset" => "BTC.BTC", "amount" => "1000", "decimals" => "0"}],
              "gas" => [%{"asset" => "BTC.BTC", "amount" => "10", "decimals" => "0"}],
              "memo" => "=:THOR.RUNE:thor1abc"
            },
            "block_height" => "100",
            "finalise_height" => "101",
            "observed_pub_key" => "thorpub1addwnpepq"
          }
        end)
    }
  end

  defp txs(samples) when is_list(samples) do
    assert {:ok, %Block{txs: txs}} = Block.new(response(Enum.map(samples, &block_tx/1)))
    txs
  end

  defp txs(sample), do: txs([sample])

  defp block_tx(%{"hash" => hash, "code" => code, "tx" => tx}) do
    %QueryBlockTx{hash: hash, tx: JSON.encode!(tx), result: result(code)}
  end

  defp result(code), do: %BlockTxResult{code: code, events: []}

  defp response(txs) do
    %QueryBlockResponse{
      header: %BlockResponseHeader{
        height: 7,
        chain_id: "thorchain-1",
        time: "2026-09-26T12:00:00.123456789Z"
      },
      txs: txs
    }
  end
end
