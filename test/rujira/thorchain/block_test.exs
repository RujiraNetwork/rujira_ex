defmodule Rujira.Thorchain.BlockTest do
  @moduledoc """
  The cache is global, so this case runs sync and every cached read uses a
  height of its own.
  """
  use Rujira.Test.CacheCase, async: false

  import ExUnit.CaptureLog

  alias Rujira.Events
  alias Rujira.Test.MockNode
  alias Rujira.Thorchain.Block
  alias Rujira.Thorchain.Events.Event, as: TcEvent
  alias Rujira.Thorchain.Events.SetMimir
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

  describe "new/1" do
    test "keeps the header's nanosecond time at microsecond precision" do
      assert {:ok, %Block{height: 7, chain_id: "thorchain-1", time: time, events: []}} =
               Block.new(response(7))

      assert time == ~U[2026-09-26 12:00:00.123456Z]
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

  # --- Fixtures ---

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

  defp drain(acc \\ []) do
    receive do
      {:mock_node, _request, opts} -> drain([opts | acc])
    after
      0 -> Enum.reverse(acc)
    end
  end
end
