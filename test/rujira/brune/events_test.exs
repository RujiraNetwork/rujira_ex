defmodule Rujira.Brune.EventsTest do
  use ExUnit.Case, async: true

  alias Rujira.Brune.Events
  alias Rujira.Brune.Events.Burn
  alias Rujira.Brune.Events.Event, as: BruneEvent
  alias Rujira.Brune.Events.FeeAllocate
  alias Rujira.Brune.Events.FeeDistribute
  alias Rujira.Brune.Events.Mint
  alias Rujira.Brune.Events.NodeBond
  alias Rujira.Brune.Events.NodeDeregister
  alias Rujira.Brune.Events.NodeLeave
  alias Rujira.Brune.Events.NodeRegister
  alias Rujira.Brune.Events.NodeUnbond
  alias Rujira.Brune.Events.Warn
  alias Rujira.Events.Event

  defp parse(type, attrs) do
    Events.parse(Event.new(type, Map.put(attrs, "_contract_address", "thor1abc")))
  end

  describe "mint" do
    test "parses recipient and coin" do
      assert {:ok, %BruneEvent{address: "thor1abc", data: data}} =
               parse("wasm-rujira-brune/mint", %{
                 "recipient" => "thor1r",
                 "amount" => "100",
                 "denom" => "x/ruji"
               })

      assert %Mint{recipient: "thor1r", coin: coin} = data
      assert coin.amount == 100
      assert coin.asset.id == "THOR.RUJI"
    end

    test "errors on missing fields" do
      assert {:error, :invalid_attrs} = parse("wasm-rujira-brune/mint", %{})
    end

    test "errors on an invalid denom" do
      assert {:error, _} =
               parse("wasm-rujira-brune/mint", %{
                 "recipient" => "thor1r",
                 "amount" => "100",
                 "denom" => ""
               })
    end
  end

  describe "burn" do
    test "parses sender and coin" do
      assert {:ok, %BruneEvent{data: %Burn{sender: "thor1s", coin: coin}}} =
               parse("wasm-rujira-brune/burn", %{
                 "sender" => "thor1s",
                 "amount" => "50",
                 "denom" => "btc-btc"
               })

      assert coin.amount == 50
      assert coin.asset.id == "BTC-BTC"
    end

    test "errors on missing fields" do
      assert {:error, :invalid_attrs} = parse("wasm-rujira-brune/burn", %{})
    end
  end

  describe "node.register / node.deregister / node.leave" do
    test "node.register parses the node" do
      assert {:ok, %BruneEvent{data: %NodeRegister{node: "thor1node"}}} =
               parse("wasm-rujira-brune/node.register", %{"node" => "thor1node"})
    end

    test "node.register errors on missing node" do
      assert {:error, :invalid_attrs} = parse("wasm-rujira-brune/node.register", %{})
    end

    test "node.deregister parses the node" do
      assert {:ok, %BruneEvent{data: %NodeDeregister{node: "thor1node"}}} =
               parse("wasm-rujira-brune/node.deregister", %{"node" => "thor1node"})
    end

    test "node.deregister errors on missing node" do
      assert {:error, :invalid_attrs} = parse("wasm-rujira-brune/node.deregister", %{})
    end

    test "node.leave parses the node" do
      assert {:ok, %BruneEvent{data: %NodeLeave{node: "thor1node"}}} =
               parse("wasm-rujira-brune/node.leave", %{"node" => "thor1node"})
    end

    test "node.leave errors on missing node" do
      assert {:error, :invalid_attrs} = parse("wasm-rujira-brune/node.leave", %{})
    end
  end

  describe "node.bond / node.unbond" do
    test "node.bond parses node and amount" do
      assert {:ok, %BruneEvent{data: %NodeBond{node: "thor1node", amount: 1000}}} =
               parse("wasm-rujira-brune/node.bond", %{"node" => "thor1node", "amount" => "1000"})
    end

    test "node.bond errors on missing amount" do
      assert {:error, :invalid_attrs} =
               parse("wasm-rujira-brune/node.bond", %{"node" => "thor1node"})
    end

    test "node.unbond parses node and amount" do
      assert {:ok, %BruneEvent{data: %NodeUnbond{node: "thor1node", amount: 500}}} =
               parse("wasm-rujira-brune/node.unbond", %{
                 "node" => "thor1node",
                 "amount" => "500"
               })
    end

    test "node.unbond errors on missing amount" do
      assert {:error, :invalid_attrs} =
               parse("wasm-rujira-brune/node.unbond", %{"node" => "thor1node"})
    end
  end

  describe "fee.allocate / fee.distribute" do
    test "fee.allocate parses amount as a decimal" do
      assert {:ok, %BruneEvent{data: %FeeAllocate{amount: amount}}} =
               parse("wasm-rujira-brune/fee.allocate", %{"amount" => "12.5"})

      assert Decimal.equal?(amount, Decimal.new("12.5"))
    end

    test "fee.allocate errors on missing amount" do
      assert {:error, :invalid_attrs} = parse("wasm-rujira-brune/fee.allocate", %{})
    end

    test "fee.distribute parses amount as an integer amount" do
      assert {:ok, %BruneEvent{data: %FeeDistribute{amount: 250}}} =
               parse("wasm-rujira-brune/fee.distribute", %{"amount" => "250"})
    end

    test "fee.distribute errors on missing amount" do
      assert {:error, :invalid_attrs} = parse("wasm-rujira-brune/fee.distribute", %{})
    end
  end

  describe "warn" do
    test "parses the message" do
      assert {:ok, %BruneEvent{data: %Warn{message: "low capacity"}}} =
               parse("wasm-rujira-brune/warn", %{"message" => "low capacity"})
    end

    test "errors on missing message" do
      assert {:error, :invalid_attrs} = parse("wasm-rujira-brune/warn", %{})
    end
  end

  describe "fallbacks" do
    test "wraps unknown sub-type in the envelope" do
      assert {:ok, %BruneEvent{address: "thor1abc", data: %Event{}}} =
               parse("wasm-rujira-brune/unknown_action", %{})
    end

    test "wraps a non-wasm event with nil address" do
      e = Event.new("something_else", %{})

      assert {:ok, %BruneEvent{address: nil, data: %Event{type: "something_else"}}} =
               Events.parse(e)
    end
  end
end
