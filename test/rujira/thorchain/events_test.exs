defmodule Rujira.Thorchain.EventsTest do
  use ExUnit.Case, async: true

  alias Rujira.Coin
  alias Rujira.Events.Event
  alias Rujira.Thorchain.Events
  alias Rujira.Thorchain.Events.Event, as: TcEvent

  defp event(type, attrs), do: Event.new(type, attrs)

  defp swap_attrs(extra \\ %{}) do
    Map.merge(
      %{
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
      },
      extra
    )
  end

  test "parses swap with single in/out coins and numeric fields" do
    assert {:ok, %TcEvent{data: data}} = Events.parse(event("swap", swap_attrs()))

    assert %Events.Swap{
             pool: "BTC.BTC",
             id: "ABC",
             chain: "BTC",
             swap_target: 300_000_000,
             swap_slip: 150,
             liquidity_fee: 1000,
             liquidity_fee_in_rune: 2000,
             pool_slip: 150,
             streaming_swap_quantity: 3,
             streaming_swap_count: 1,
             synth_units: nil
           } = data

    assert %Coin{amount: 100_000_000} = data.coin
    assert data.coin.asset.ticker == "BTC"
    assert %Coin{amount: 300_000_000} = data.emit_asset
  end

  test "parses swap synth_units only when present" do
    assert {:ok, %TcEvent{data: %Events.Swap{synth_units: 500}}} =
             Events.parse(event("swap", swap_attrs(%{"synth_units" => "500"})))
  end

  test "fails swap when a compulsory attribute is missing" do
    attrs = Map.delete(swap_attrs(), "swap_target")
    assert {:error, _} = Events.parse(event("swap", attrs))
  end

  test "parses transfer into a list of coins" do
    assert {:ok, %TcEvent{data: %Events.Transfer{sender: "a", recipient: "b", coins: coins}}} =
             Events.parse(
               event("transfer", %{
                 "sender" => "a",
                 "recipient" => "b",
                 "amount" => "100rune,2000000tcy"
               })
             )

    assert [%Coin{amount: 100}, %Coin{amount: 2_000_000}] = coins
  end

  test "parses add_liquidity" do
    assert {:ok,
            %TcEvent{
              data: %Events.AddLiquidity{
                pool: "BTC.BTC",
                rune_address: "thor1r",
                asset_address: "bc1a",
                liquidity_provider_units: 5000,
                rune_amount: 100,
                asset_amount: 200
              }
            }} =
             Events.parse(
               event("add_liquidity", %{
                 "pool" => "BTC.BTC",
                 "rune_address" => "thor1r",
                 "asset_address" => "bc1a",
                 "liquidity_provider_units" => "5000",
                 "rune_amount" => "100",
                 "asset_amount" => "200"
               })
             )
  end

  test "parses withdraw" do
    assert {:ok, %TcEvent{data: data}} =
             Events.parse(
               event("withdraw", %{
                 "pool" => "ETH.ETH",
                 "id" => "DEF",
                 "chain" => "THOR",
                 "from" => "thor1f",
                 "to" => "thor1t",
                 "memo" => "-:ETH.ETH:10000",
                 "coin" => "1 THOR.RUNE",
                 "liquidity_provider_units" => "5000",
                 "basis_points" => "10000",
                 "asymmetry" => "0.5",
                 "emit_asset" => "100",
                 "emit_rune" => "200"
               })
             )

    assert %Events.Withdraw{
             pool: "ETH.ETH",
             basis_points: 10_000,
             liquidity_provider_units: 5000,
             emit_asset: 100,
             emit_rune: 200
           } = data

    assert Decimal.equal?(data.asymmetry, Decimal.new("0.5"))
    assert %Coin{amount: 1} = data.coin
  end

  test "parses pending_liquidity" do
    assert {:ok,
            %TcEvent{
              data: %Events.PendingLiquidity{
                pool: "BTC.BTC",
                type: "add",
                rune_amount: 100,
                asset_amount: 200
              }
            }} =
             Events.parse(
               event("pending_liquidity", %{
                 "pool" => "BTC.BTC",
                 "type" => "add",
                 "rune_address" => "thor1r",
                 "asset_address" => "bc1a",
                 "rune_amount" => "100",
                 "asset_amount" => "200"
               })
             )
  end

  test "parses oracle_price" do
    assert {:ok, %TcEvent{data: %Events.OraclePrice{symbol: "ETH.ETH", price: price}}} =
             Events.parse(event("oracle_price", %{"symbol" => "ETH.ETH", "price" => "3800"}))

    assert Decimal.equal?(price, Decimal.new("3800"))
  end

  test "parses bond" do
    assert {:ok,
            %TcEvent{
              data: %Events.Bond{
                amount: 100,
                bond_type: "bond_paid",
                node_address: "thor1node",
                bond_address: "thor1bond"
              }
            }} =
             Events.parse(
               event("bond", %{
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
               })
             )
  end

  test "parses rebond" do
    assert {:ok,
            %TcEvent{
              data: %Events.Rebond{
                amount: 100,
                node_address: "thor1node",
                old_bond_address: "thor1old",
                new_bond_address: "thor1new"
              }
            }} =
             Events.parse(
               event("rebond", %{
                 "amount" => "100",
                 "node_address" => "thor1node",
                 "old_bond_address" => "thor1old",
                 "new_bond_address" => "thor1new",
                 "id" => "TX2",
                 "chain" => "THOR",
                 "from" => "thor1from",
                 "to" => "thor1to",
                 "memo" => "REBOND:thor1node",
                 "coin" => "100 THOR.RUNE"
               })
             )
  end

  test "parses set_mimir" do
    assert {:ok, %TcEvent{data: %Events.SetMimir{key: "Halt", value: "1"}}} =
             Events.parse(event("set_mimir", %{"key" => "Halt", "value" => "1"}))
  end

  test "wraps unknown type in envelope" do
    assert {:ok, %TcEvent{data: %Event{type: "unknown"}}} =
             Events.parse(event("unknown", %{}))
  end
end
