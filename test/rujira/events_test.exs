defmodule Rujira.EventsTest do
  use ExUnit.Case, async: true

  alias Rujira.Events
  alias Rujira.Fin.Events.Event, as: FinEvent
  alias Rujira.Fin.Events.RangeCreate
  alias Rujira.Fin.Events.Trade
  alias Rujira.Thorchain.Events.AffiliateFee
  alias Rujira.Thorchain.Events.Bond
  alias Rujira.Thorchain.Events.Event, as: TcEvent
  alias Rujira.Thorchain.Events.OraclePrice
  alias Rujira.Thorchain.Events.Rewards
  alias Rujira.Thorchain.Events.SetMimir
  alias Rujira.Thorchain.Events.Swap
  alias Rujira.Thorchain.Events.Transfer

  describe "parse/1 — FIN routing" do
    test "routes wasm-rujira-fin/* to Fin envelope" do
      event = %{
        type: "wasm-rujira-fin/trade",
        attributes: %{
          "_contract_address" => "thor1abc",
          "side" => "Base",
          "price" => "fixed:100",
          "rate" => "100",
          "offer" => "1",
          "bid" => "100"
        }
      }

      assert {:ok, %FinEvent{address: "thor1abc", data: %Trade{side: :base}}} =
               Events.parse(event)
    end

    test "routes range events to Fin envelope" do
      event = %{
        type: "wasm-rujira-fin/range.create",
        attributes: %{
          "_contract_address" => "thor1abc",
          "idx" => "1",
          "owner" => "thor1x",
          "high" => "2.0",
          "low" => "1.0",
          "skew" => "0",
          "spread" => "0.01",
          "fee" => "0.003",
          "base" => "1000",
          "quote" => "2000"
        }
      }

      assert {:ok, %FinEvent{address: "thor1abc", data: %RangeCreate{idx: 1}}} =
               Events.parse(event)
    end

    test "matches all FIN events at protocol level" do
      event = %{
        type: "wasm-rujira-fin/trade",
        attributes: %{
          "_contract_address" => "thor1abc",
          "side" => "Base",
          "price" => "fixed:100",
          "rate" => "100",
          "offer" => "1",
          "bid" => "100"
        }
      }

      assert {:ok, %FinEvent{}} = Events.parse(event)
    end
  end

  describe "parse/1 — Thorchain native routing" do
    test "routes swap" do
      attrs = %{
        "pool" => "BTC.BTC",
        "id" => "ABC",
        "chain" => "BTC",
        "from" => "bc1from",
        "to" => "thorto",
        "memo" => "=:THOR.RUNE",
        "coin" => "100000000 BTC.BTC",
        "emit_asset" => "300000000 THOR.RUNE",
        "swap_target" => "300000000",
        "swap_slip" => "150",
        "liquidity_fee" => "1000",
        "liquidity_fee_in_rune" => "2000",
        "pool_slip" => "150",
        "streaming_swap_quantity" => "3",
        "streaming_swap_count" => "1"
      }

      assert {:ok, %TcEvent{data: %Swap{pool: "BTC.BTC"}}} =
               Events.parse(%{type: "swap", attributes: attrs})
    end

    test "routes transfer" do
      assert {:ok, %TcEvent{data: %Transfer{sender: "a", recipient: "b", coins: [_]}}} =
               Events.parse(%{
                 type: "transfer",
                 attributes: %{"sender" => "a", "recipient" => "b", "amount" => "1rune"}
               })
    end

    test "routes oracle_price" do
      assert {:ok, %TcEvent{data: %OraclePrice{symbol: "ETH.ETH"}}} =
               Events.parse(%{
                 type: "oracle_price",
                 attributes: %{"symbol" => "ETH.ETH", "price" => "3800"}
               })
    end

    test "routes set_mimir" do
      assert {:ok, %TcEvent{data: %SetMimir{key: "Halt"}}} =
               Events.parse(%{type: "set_mimir", attributes: %{"key" => "Halt", "value" => "1"}})
    end

    test "routes bond" do
      assert {:ok, %TcEvent{data: %Bond{node_address: "thor1node"}}} =
               Events.parse(%{
                 type: "bond",
                 attributes: %{
                   "amount" => "100",
                   "bond_type" => "bond_paid",
                   "node_address" => "thor1node",
                   "bond_address" => "thor1bond",
                   "id" => "TX1",
                   "chain" => "THOR",
                   "from" => "thor1from",
                   "to" => "thor1to",
                   "memo" => "BOND:thor1node",
                   "coin" => "100 THOR.RUNE"
                 }
               })
    end

    test "routes rewards" do
      assert {:ok, %TcEvent{data: %Rewards{bond_reward: 1000}}} =
               Events.parse(%{
                 type: "rewards",
                 attributes: %{
                   "bond_reward" => "1000",
                   "dev_fund_reward" => "10",
                   "income_burn" => "5",
                   "tcy_stake_reward" => "20",
                   "marketing_fund_reward" => "30",
                   "pol_reserve_reward" => "40"
                 }
               })
    end

    test "routes affiliate_fee" do
      assert {:ok, %TcEvent{data: %AffiliateFee{thorname: "t"}}} =
               Events.parse(%{
                 type: "affiliate_fee",
                 attributes: %{
                   "tx_id" => "TX1",
                   "memo" => "=:BTC.BTC",
                   "thorname" => "t",
                   "rune_address" => "thor1r",
                   "asset" => "BTC.BTC",
                   "gross_amount" => "1000",
                   "fee_bps" => "50",
                   "fee_amount" => "5"
                 }
               })
    end

    test "matches all Thorchain events at protocol level" do
      assert {:ok, %TcEvent{}} =
               Events.parse(%{type: "set_mimir", attributes: %{"key" => "Halt", "value" => "1"}})
    end
  end

  describe "parse/1 — unmatched" do
    test "returns default event for not-yet-implemented protocols" do
      assert {:ok, %Rujira.Events.Event{type: "wasm-rujira-bow/swap", attributes: %{}}} =
               Events.parse(%{type: "wasm-rujira-bow/swap", attributes: %{}})
    end

    test "returns default event for unknown events" do
      assert {:ok, %Rujira.Events.Event{type: "something_random", attributes: %{}}} =
               Events.parse(%{type: "something_random", attributes: %{}})
    end

    test "returns error for invalid input" do
      assert {:error, :invalid_event} = Events.parse("not an event")
    end
  end

  describe "cast/1" do
    test "casts BlockEvent proto to map" do
      block_event = %Thorchain.Types.BlockEvent{
        event_kv_pair: [
          %{key: "type", value: "swap"},
          %{key: "pool", value: "BTC.BTC"},
          %{key: "id", value: "123"}
        ]
      }

      assert %{type: "swap", attributes: %{"pool" => "BTC.BTC", "id" => "123"}} =
               Events.cast(block_event)
    end
  end

  describe "parse/1 — raw BlockEvent proto" do
    test "casts and parses in one step" do
      block_event = %Thorchain.Types.BlockEvent{
        event_kv_pair: [
          %{key: "type", value: "oracle_price"},
          %{key: "symbol", value: "ETH.ETH"},
          %{key: "price", value: "3800"}
        ]
      }

      assert {:ok, %TcEvent{data: %OraclePrice{symbol: "ETH.ETH", price: price}}} =
               Events.parse(block_event)

      assert Decimal.equal?(price, Decimal.new("3800"))
    end
  end
end
