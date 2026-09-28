defmodule Rujira.Cache.InvalidatorTest do
  @moduledoc """
  The pure half of `advance/1`: what a block changed, read from the block
  alone.
  """
  use ExUnit.Case, async: true

  alias Rujira.Cache.Invalidator
  alias Rujira.Fin.Events.Event, as: FinEvent
  alias Rujira.Thorchain.Block
  alias Thorchain.Types.BlockEvent
  alias Thorchain.Types.BlockResponseHeader
  alias Thorchain.Types.BlockTxResult
  alias Thorchain.Types.EventKeyValuePair
  alias Thorchain.Types.QueryBlockResponse
  alias Thorchain.Types.QueryBlockTx

  describe "sources/1" do
    test "every block changes :per_block, even an empty one" do
      assert Invalidator.sources(block()) == [:per_block]
    end

    test "a raw contract event names its contract" do
      sources =
        [event("wasm", %{"_contract_address" => "thor1pair"})]
        |> block()
        |> Invalidator.sources()

      assert {:contract, "thor1pair"} in sources
    end

    test "a parsed protocol envelope still names its contract" do
      block =
        block([
          event("wasm-rujira-fin/trade", %{
            "_contract_address" => "thor1pair",
            "side" => "base",
            "price" => "fixed:1.5",
            "rate" => "1.5",
            "offer" => "100",
            "bid" => "150"
          })
        ])

      assert [%{event: %FinEvent{address: "thor1pair"}}] = block.events
      assert {:contract, "thor1pair"} in Invalidator.sources(block)
    end

    test "instantiate, migrate and store_code change the registry" do
      for type <- ~w(instantiate migrate store_code) do
        assert :contract_registry in Invalidator.sources(block([event(type)]))
      end
    end

    test "coin_spent and coin_received change a balance and the denom's transfers" do
      sources =
        block([
          event("coin_spent", %{"spender" => "thor1a", "amount" => "100rune"}),
          event("coin_received", %{"receiver" => "thor1b", "amount" => "100rune,5x/ruji"})
        ])
        |> Invalidator.sources()

      assert {:balance, "thor1a"} in sources
      assert {:balance, "thor1b"} in sources
      assert {:denom_transfers, "rune"} in sources
      assert {:denom_transfers, "x/ruji"} in sources
    end

    test "create_denom changes the denom's metadata, in whatever stage it was emitted" do
      attrs = %{"creator" => "thor1admin", "new_token_denom" => "x/brune"}
      created = event("create_denom", attrs)

      for block <- [
            block([created]),
            block([], [created]),
            block([], [], [tx("H", 0, [created])])
          ] do
        assert {:denom_metadata, "x/brune"} in Invalidator.sources(block)
      end
    end

    test "create_denom names the denom exactly, and names none without the attribute" do
      sources =
        Invalidator.sources(block([event("create_denom", %{"new_token_denom" => "x/Brune"})]))

      assert {:denom_metadata, "x/Brune"} in sources
      refute {:denom_metadata, "x/brune"} in sources

      assert Invalidator.sources(block([event("create_denom", %{"creator" => "thor1a"})])) ==
               [:per_block]
    end

    test "an upgrade changes everything, in whatever stage it was emitted" do
      assert :all in Invalidator.sources(block([event("version", %{"version" => "3.10.0"})]))
      assert :all in Invalidator.sources(block([], [event("version", %{})]))
    end

    test "a failed transaction's events count too" do
      block =
        block(
          [],
          [],
          [
            tx("HASH", 1, [event("coin_spent", %{"spender" => "thor1payer", "amount" => "2rune"})])
          ]
        )

      assert {:balance, "thor1payer"} in Invalidator.sources(block)
    end

    test "a THORChain module event contributes nothing of its own" do
      sources = Invalidator.sources(block([event("set_mimir", %{"key" => "K", "value" => "1"})]))

      assert sources == [:per_block]
    end

    test "sources are unique" do
      sources =
        block([
          event("wasm", %{"_contract_address" => "thor1pair"}),
          event("wasm", %{"_contract_address" => "thor1pair"})
        ])
        |> Invalidator.sources()

      assert Enum.sort(sources) == Enum.sort([:per_block, {:contract, "thor1pair"}])
    end
  end

  # --- Fixtures ---

  defp block(begin_events \\ [], pre_events \\ [], txs \\ []) do
    {:ok, block} =
      Block.new(%QueryBlockResponse{
        header: %BlockResponseHeader{height: 1, chain_id: "thorchain-1", time: ""},
        begin_block_events: begin_events,
        finalize_block_events: pre_events,
        end_block_events: [],
        txs: txs
      })

    block
  end

  defp tx(hash, code, events) do
    %QueryBlockTx{hash: hash, result: %BlockTxResult{code: code, events: events}}
  end

  defp event(type, attrs \\ %{}) do
    pairs = Enum.map(attrs, fn {key, value} -> %EventKeyValuePair{key: key, value: value} end)
    %BlockEvent{event_kv_pair: [%EventKeyValuePair{key: "type", value: type} | pairs]}
  end
end
