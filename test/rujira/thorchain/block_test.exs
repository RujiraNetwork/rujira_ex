defmodule Rujira.Thorchain.BlockTest do
  @moduledoc """
  The cache is global, so this case runs sync and every cached read uses a
  height of its own.
  """
  use Rujira.Test.CacheCase, async: false

  import ExUnit.CaptureLog

  alias Cosmos.Bank.V1beta1.Metadata, as: DenomMetadata
  alias Cosmos.Bank.V1beta1.QueryDenomMetadataRequest
  alias Cosmos.Bank.V1beta1.QueryDenomMetadataResponse
  alias Rujira.Coin
  alias Rujira.Events
  alias Rujira.Test.MockNode
  alias Rujira.Thorchain.Block
  alias Rujira.Thorchain.Events.Event, as: TcEvent
  alias Rujira.Thorchain.Events.SetMimir
  alias Rujira.Thorchain.Events.Transfer
  alias Thorchain.Types.BlockEvent
  alias Thorchain.Types.BlockResponseHeader
  alias Thorchain.Types.BlockTxResult
  alias Thorchain.Types.EventKeyValuePair
  alias Thorchain.Types.QueryBlockRequest
  alias Thorchain.Types.QueryBlockResponse
  alias Thorchain.Types.QueryBlockTx

  @unavailable %GRPC.RPCError{
    status: 2,
    message: "failed to load state at height 100004: version does not exist"
  }
  @other %GRPC.RPCError{status: 2, message: "boom"}
  @dropped %GRPC.RPCError{status: 14, message: "upstream connect error"}

  describe "new/1" do
    test "keeps the header's nanosecond time at microsecond precision" do
      assert {:ok, %Block{height: 7, chain_id: "thorchain-1", time: time, events: []}} =
               Block.new(response(7))

      assert time == ~U[2026-09-26 12:00:00.123456Z]
      assert time.microsecond == {123_456, 6}
    end

    test "a time the node rendered with trailing zeros trimmed is still microsecond precision" do
      for {rendered, microsecond} <- [
            {"2026-09-29T14:29:59.85054Z", {850_540, 6}},
            {"2026-09-29T14:29:59.5Z", {500_000, 6}},
            {"2026-09-29T14:29:59Z", {0, 6}}
          ] do
        assert {:ok, %Block{time: time}} = Block.new(response(7, time: rendered))
        assert time.microsecond == microsecond
      end
    end

    test "an unparsable time is an error, an absent one is nil" do
      assert {:error, :invalid_time} = Block.new(response(7, time: "yesterday"))
      assert {:ok, %Block{time: nil}} = Block.new(response(7, time: ""))
    end

    test "a response without a header is not a block" do
      assert {:error, :invalid_attrs} = Block.new(%QueryBlockResponse{})
    end
  end

  describe "event order" do
    test "every stage is placed in execution order, with the tx hash on tx events" do
      height = 100_001

      MockNode.expect(fn %QueryBlockRequest{height: "100001"} ->
        {:ok,
         response(height,
           finalize_events: [event("pre_a"), event("pre_b")],
           begin_events: [event("begin_a")],
           end_events: [event("end_a")],
           txs: [
             tx("HASH0", [event("tx0_a"), event("tx0_b")]),
             tx("HASH1", [event("tx1_a")])
           ]
         )}
      end)

      assert {:ok, %Block{events: events}} = Block.get(height)

      assert Enum.map(events, &{&1.stage, &1.tx_idx, &1.event_idx, &1.txhash, &1.event.type}) == [
               {:pre_block, -2, 0, nil, "pre_a"},
               {:pre_block, -2, 1, nil, "pre_b"},
               {:begin, -1, 0, nil, "begin_a"},
               {:tx, 0, 0, "HASH0", "tx0_a"},
               {:tx, 0, 1, "HASH0", "tx0_b"},
               {:tx, 1, 0, "HASH1", "tx1_a"},
               {:end, 2_147_483_647, 0, nil, "end_a"}
             ]
    end

    test "a block parsed in parallel keeps its transactions and events in block order" do
      count = 24
      suffixes = ~w(a b c)

      txs =
        for i <- 0..(count - 1),
            do: tx("HASH#{i}", Enum.map(suffixes, &event("tx#{i}_#{&1}")))

      assert {:ok, %Block{txs: parsed, events: events}} =
               Block.new(
                 response(100_010,
                   finalize_events: [event("pre_a")],
                   begin_events: [event("begin_a")],
                   end_events: [event("end_a")],
                   txs: txs
                 )
               )

      assert Enum.map(parsed, &{&1.idx, &1.hash}) ==
               Enum.map(0..(count - 1), &{&1, "HASH#{&1}"})

      tx_order =
        for i <- 0..(count - 1),
            {suffix, event_idx} <- Enum.with_index(suffixes),
            do: {:tx, i, event_idx, "HASH#{i}", "tx#{i}_#{suffix}"}

      assert Enum.map(events, &{&1.stage, &1.tx_idx, &1.event_idx, &1.txhash, &1.event.type}) ==
               [{:pre_block, -2, 0, nil, "pre_a"}, {:begin, -1, 0, nil, "begin_a"}] ++
                 tx_order ++ [{:end, 2_147_483_647, 0, nil, "end_a"}]
    end

    test "the stage sentinels bracket every transaction index" do
      assert Block.pre_block_tx_idx() < Block.begin_block_tx_idx()
      assert Block.begin_block_tx_idx() < 0
      assert Block.end_block_tx_idx() == 2_147_483_647
    end

    test "a recognised event is parsed into its protocol envelope" do
      height = 100_002

      MockNode.expect(fn %QueryBlockRequest{} ->
        {:ok,
         response(height,
           txs: [tx("HASH0", [event("set_mimir", %{"key" => "HALTTHORCHAIN", "value" => "1"})])]
         )}
      end)

      assert {:ok, %Block{events: [block_event]}} = Block.get(height)

      assert %{
               stage: :tx,
               txhash: "HASH0",
               event: %TcEvent{data: %SetMimir{key: "HALTTHORCHAIN", value: "1"}}
             } = block_event
    end

    test "a malformed known event is kept unparsed and warned about" do
      height = 100_003

      MockNode.expect(fn %QueryBlockRequest{} ->
        {:ok, response(height, begin_events: [event("set_mimir", %{"key" => "HALTTHORCHAIN"})])}
      end)

      log = capture_log(fn -> assert {:ok, %Block{}} = Block.get(height) end)

      assert {:ok, %Block{events: [%{event: unparsed}]}} = Block.get(height)

      assert %Events.Event{type: "set_mimir", attributes: %{"key" => "HALTTHORCHAIN"}} = unparsed

      assert log =~ "height=#{height}"
      assert log =~ "stage=begin"
      assert log =~ "tx_idx=-1"
      assert log =~ "event_idx=0"
      assert log =~ "type=set_mimir"
      assert log =~ ":invalid_attrs"
    end

    test "an event with no leading type pair casts to a nil-typed event and keeps its position" do
      height = 100_012

      MockNode.expect(fn %QueryBlockRequest{} ->
        {:ok,
         response(height,
           begin_events: [
             event("begin_a"),
             untyped_event(%{"pool" => "BTC.BTC"}),
             event("begin_b")
           ]
         )}
      end)

      assert {:ok, %Block{events: events}} = Block.get(height)

      assert Enum.map(events, &{&1.event_idx, &1.event}) == [
               {0, %Events.Event{type: "begin_a", attributes: %{}}},
               {1, %Events.Event{type: nil, attributes: %{"pool" => "BTC.BTC"}}},
               {2, %Events.Event{type: "begin_b", attributes: %{}}}
             ]
    end
  end

  describe "tx result" do
    test "a tx with a nil result yields no events and doesn't shift later tx indices" do
      height = 100_013

      MockNode.expect(fn %QueryBlockRequest{} ->
        {:ok,
         response(height,
           txs: [
             tx("HASH0", [event("tx0_a")]),
             %QueryBlockTx{hash: "HASH1", result: nil},
             tx("HASH2", [event("tx2_a")])
           ]
         )}
      end)

      assert {:ok, %Block{events: events}} = Block.get(height)

      assert Enum.map(events, &{&1.tx_idx, &1.txhash, &1.event.type}) == [
               {0, "HASH0", "tx0_a"},
               {2, "HASH2", "tx2_a"}
             ]
    end
  end

  describe "get/2" do
    test ":latest asks for no height and is never cached" do
      MockNode.expect(fn %QueryBlockRequest{height: ""} -> {:ok, response(4242)} end)

      assert {:ok, %Block{height: 4242}} = Block.get()
      assert {:ok, %Block{height: 4242}} = Block.get(:latest)

      assert_received {:mock_node, %QueryBlockRequest{}, _}
      assert_received {:mock_node, %QueryBlockRequest{}, _}
    end

    test "a :height opt is dropped - the height travels in the request" do
      height = 100_004

      MockNode.expect(fn %QueryBlockRequest{height: "100004"} -> {:ok, response(height)} end)

      assert {:ok, %Block{height: ^height}} = Block.get(height, height: 99)
      assert_received {:mock_node, %QueryBlockRequest{}, opts}
      refute Keyword.has_key?(opts, :height)
      refute Keyword.has_key?(opts, :metadata)
    end

    test "a block for another height is an error, never data" do
      height = 100_005

      MockNode.expect(fn %QueryBlockRequest{height: "100005"} -> {:ok, response(88)} end)

      assert {:error, {:height_mismatch, ^height, 88}} = Block.get(height)
    end

    test "a height out of range never reaches the node" do
      for height <- [0, -1, 9_223_372_036_854_775_808, "100", :next] do
        assert {:error, :invalid_height} = Block.get(height)
      end

      refute_received {:mock_node, _, _}
    end

    test "a height the node cannot serve is unavailable, any other error is unchanged" do
      MockNode.expect(fn
        %QueryBlockRequest{height: "100006"} -> {:error, @unavailable}
        %QueryBlockRequest{height: "100007"} -> {:error, @other}
        %QueryBlockRequest{height: ""} -> {:error, @unavailable}
      end)

      assert {:error, {:height_unavailable, 100_006}} = Block.get(100_006)
      assert {:error, @other} = Block.get(100_007)
      assert {:error, @unavailable} = Block.get(:latest)
    end

    test "the facade exposes both arities" do
      MockNode.expect(fn %QueryBlockRequest{height: height} ->
        {:ok, response(if(height == "", do: 4242, else: 100_008))}
      end)

      assert {:ok, %Block{height: 4242}} = Rujira.Thorchain.block()
      assert {:ok, %Block{height: 100_008}} = Rujira.Thorchain.block(100_008, [])
    end
  end

  describe "caching" do
    test "an integer height is read once, then served from the cache" do
      height = 100_009

      MockNode.expect(fn %QueryBlockRequest{} -> {:ok, response(height)} end)

      assert {:ok, block} = Block.get(height)
      assert [_] = drain()

      assert {:ok, ^block} = Block.get(height)
      assert [] = drain()
    end

    test "a failed read is not cached, so the next call retries" do
      height = 100_010

      MockNode.expect(fn %QueryBlockRequest{} ->
        case Process.get(:calls, 0) do
          0 ->
            Process.put(:calls, 1)
            {:error, @other}

          _ ->
            {:ok, response(height)}
        end
      end)

      assert {:error, @other} = Block.get(height)
      assert {:ok, %Block{height: ^height}} = Block.get(height)
      assert [_, _] = drain()
    end

    test "a block is read at its own height, and needs no head" do
      height = 100_011

      reset_cache()
      MockNode.expect(fn %QueryBlockRequest{} -> {:ok, response(height)} end)

      assert {:ok, %Block{height: ^height}} = Block.get(height)
      assert [_] = drain()
      assert {:ok, %Block{height: ^height}} = Block.get(height)
      assert [] = drain()
    end

    test "invalidate_all drops a cached block" do
      height = 100_012

      MockNode.expect(fn %QueryBlockRequest{} -> {:ok, response(height)} end)

      assert {:ok, _} = Block.get(height)
      assert [_] = drain()

      Rujira.Cache.invalidate_all()

      assert {:ok, _} = Block.get(height)
      assert [_] = drain()
    end

    test "concurrent reads of the same height reach the node once and agree" do
      height = 100_014
      counter = :counters.new(1, [])

      MockNode.expect(fn %QueryBlockRequest{} ->
        :counters.add(counter, 1, 1)
        Process.sleep(10)
        {:ok, response(height)}
      end)

      task1 = Task.async(fn -> Block.get(height) end)
      task2 = Task.async(fn -> Block.get(height) end)

      assert {:ok, block1} = Task.await(task1)
      assert {:ok, block2} = Task.await(task2)
      assert block1 == block2

      assert :counters.get(counter, 1) == 1
    end
  end

  describe "a node read that fails while parsing an event" do
    test "fails the block, caches nothing, and the next healthy read is fully typed" do
      height = 100_020
      denom = "x/block-errors-a"

      MockNode.expect(fn
        %QueryBlockRequest{} -> {:ok, response(height, txs: [tx("HASH0", [transfer(denom)])])}
        %QueryDenomMetadataRequest{denom: ^denom} -> {:error, @dropped}
      end)

      assert {:error, @dropped} = Block.get(height)

      MockNode.expect(fn
        %QueryBlockRequest{} -> {:ok, response(height, txs: [tx("HASH0", [transfer(denom)])])}
        %QueryDenomMetadataRequest{denom: ^denom} -> {:ok, metadata(denom, "BLKA")}
      end)

      assert {:ok, %Block{events: [%{event: %TcEvent{data: %Transfer{coins: [coin]}}}]}} =
               Block.get(height)

      assert %Coin{amount: 100, asset: %{symbol: "BLKA"}} = coin
    end

    test "fails the block from every event stage, through get/2 and fetch_uncached/2" do
      for {stage, {key, tx_idx}, height} <- [
            {:pre_block, {:finalize_events, -2}, 100_021},
            {:begin, {:begin_events, -1}, 100_022},
            {:tx, {:txs, 0}, 100_023},
            {:end, {:end_events, 2_147_483_647}, 100_024}
          ] do
        denom = "x/block-errors-#{stage}"
        events = [event("ok_a"), transfer(denom)]
        slot = if key == :txs, do: [tx("HASH0", events)], else: events

        MockNode.expect(fn
          %QueryBlockRequest{} -> {:ok, response(height, [{key, slot}])}
          %QueryDenomMetadataRequest{denom: ^denom} -> {:error, :timeout}
        end)

        log =
          capture_log(fn ->
            assert {:error, :timeout} = Block.get(height)
            assert {:error, :timeout} = Block.fetch_uncached(height)
          end)

        assert log =~ "height=#{height} stage=#{stage} tx_idx=#{tx_idx} event_idx=1"
      end
    end

    test "a node error naming the height propagates like any other" do
      height = 100_025
      denom = "x/block-errors-height"

      MockNode.expect(fn
        %QueryBlockRequest{} -> {:ok, response(height, begin_events: [transfer(denom)])}
        %QueryDenomMetadataRequest{} -> {:error, {:height_unavailable, height}}
      end)

      assert {:error, {:height_unavailable, ^height}} = Block.get(height)
    end

    test "the first failing slot in block order wins, and every unit still runs" do
      height = 100_026
      count = 24

      # tx 3 fails slowly and tx 17 fails at once, so the later slot finishes
      # first; begin and end both fail too, and begin precedes every tx.
      txs =
        for i <- 0..(count - 1) do
          tx("HASH#{i}", [event("tx#{i}_a"), transfer("x/block-errors-tx#{i}")])
        end

      MockNode.expect(fn
        %QueryBlockRequest{} ->
          {:ok,
           response(height,
             begin_events: [event("begin_a"), transfer("x/block-errors-begin-first")],
             end_events: [transfer("x/block-errors-end-last")],
             txs: txs
           )}

        %QueryDenomMetadataRequest{denom: "x/block-errors-begin-first"} ->
          slow_error({:first, :begin})

        %QueryDenomMetadataRequest{denom: "x/block-errors-tx3"} ->
          slow_error({:tx, 3})

        %QueryDenomMetadataRequest{denom: "x/block-errors-tx17"} ->
          {:error, {:tx, 17}}

        %QueryDenomMetadataRequest{denom: "x/block-errors-end-last"} ->
          {:error, {:last, :end}}

        %QueryDenomMetadataRequest{denom: denom} ->
          {:ok, metadata(denom, "OK")}
      end)

      capture_log(fn -> assert {:error, {:first, :begin}} = Block.get(height) end)

      read = for %QueryDenomMetadataRequest{denom: denom} <- requests(), do: denom
      assert "x/block-errors-end-last" in read
      assert Enum.all?(0..(count - 1), &("x/block-errors-tx#{&1}" in read))
    end

    test "without the begin failure, the earlier of two failing transactions wins" do
      height = 100_027

      txs =
        for i <- 0..23, do: tx("HASH#{i}", [transfer("x/block-errors-b#{i}")])

      MockNode.expect(fn
        %QueryBlockRequest{} -> {:ok, response(height, txs: txs)}
        %QueryDenomMetadataRequest{denom: "x/block-errors-b3"} -> slow_error({:tx, 3})
        %QueryDenomMetadataRequest{denom: "x/block-errors-b17"} -> {:error, {:tx, 17}}
        %QueryDenomMetadataRequest{denom: denom} -> {:ok, metadata(denom, "OK")}
      end)

      capture_log(fn -> assert {:error, {:tx, 3}} = Block.get(height) end)
    end

    test "a data error in one slot still degrades while another slot's read succeeds" do
      height = 100_028
      denom = "x/block-errors-healthy"

      MockNode.expect(fn
        %QueryBlockRequest{} ->
          {:ok,
           response(height,
             begin_events: [event("set_mimir", %{"key" => "HALTTHORCHAIN"}), transfer(denom)]
           )}

        %QueryDenomMetadataRequest{denom: ^denom} ->
          {:ok, metadata(denom, "HEALTHY")}
      end)

      capture_log(fn ->
        assert {:ok, %Block{events: [%{event: unparsed}, %{event: typed}]}} = Block.get(height)
        assert %Events.Event{type: "set_mimir"} = unparsed
        assert %TcEvent{data: %Transfer{}} = typed
      end)
    end
  end

  # --- Fixtures ---

  defp transfer(denom),
    do: event("transfer", %{"sender" => "a", "recipient" => "b", "amount" => "100#{denom}"})

  defp metadata(denom, symbol) do
    %QueryDenomMetadataResponse{
      metadata: %DenomMetadata{base: denom, display: denom, symbol: symbol, denom_units: []}
    }
  end

  defp response(height, opts \\ []) do
    %QueryBlockResponse{
      header: %BlockResponseHeader{
        height: height,
        chain_id: "thorchain-1",
        time: Keyword.get(opts, :time, "2026-09-26T12:00:00.123456789Z")
      },
      begin_block_events: Keyword.get(opts, :begin_events, []),
      end_block_events: Keyword.get(opts, :end_events, []),
      finalize_block_events: Keyword.get(opts, :finalize_events, []),
      txs: Keyword.get(opts, :txs, [])
    }
  end

  defp tx(hash, events) do
    %QueryBlockTx{hash: hash, result: %BlockTxResult{code: 0, events: events}}
  end

  defp event(type, attrs \\ %{}) do
    pairs =
      Enum.map(attrs, fn {key, value} -> %EventKeyValuePair{key: key, value: value} end)

    %BlockEvent{
      event_kv_pair: [%EventKeyValuePair{key: "type", value: type} | pairs]
    }
  end

  defp untyped_event(attrs) do
    pairs = Enum.map(attrs, fn {key, value} -> %EventKeyValuePair{key: key, value: value} end)
    %BlockEvent{event_kv_pair: pairs}
  end

  defp slow_error(reason) do
    Process.sleep(20)
    {:error, reason}
  end

  defp requests(acc \\ []) do
    receive do
      {:mock_node, request, _opts} -> requests([request | acc])
    after
      0 -> Enum.reverse(acc)
    end
  end

  defp drain(acc \\ []) do
    receive do
      {:mock_node, _request, opts} -> drain([opts | acc])
    after
      0 -> Enum.reverse(acc)
    end
  end
end
