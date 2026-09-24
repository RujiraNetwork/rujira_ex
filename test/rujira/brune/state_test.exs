defmodule Rujira.Brune.StateTest do
  use ExUnit.Case, async: true

  alias Rujira.Brune.Node
  alias Rujira.Brune.Pool
  alias Rujira.Brune.State
  alias Rujira.Brune.State.Nodes
  alias Rujira.Brune.State.Revenue
  alias Rujira.Test.MockNode

  defp node_attrs(extra \\ %{}) do
    Map.merge(
      %{
        "addr" => "thor1node",
        "fee" => "0.05",
        "bond" => "100000000",
        "weight" => "1.5",
        "capacity" => "200000000",
        "is_leaving" => false,
        "status" => "active",
        "node" => %{"raw" => true}
      },
      extra
    )
  end

  defp state_attrs(extra \\ %{}) do
    Map.merge(
      %{
        "minted" => "5000000000",
        "nodes" => %{
          "bond" => "300000000",
          "weight" => "2.5",
          "capacity" => "400000000",
          "nodes" => [node_attrs()]
        },
        "revenue" => %{
          "pending" => "1000000",
          "fee_rate" => "0.02",
          "timestamp" => "1700000000000000000"
        }
      },
      extra
    )
  end

  describe "Node.new/1" do
    test "parses all fields, flooring bond/capacity" do
      assert {:ok,
              %Node{
                addr: "thor1node",
                bond: 100_000_000,
                capacity: 200_000_000,
                is_leaving: false,
                status: :active,
                node: %{"raw" => true},
                fee: fee,
                weight: weight
              }} = Node.new(node_attrs())

      assert Decimal.equal?(fee, Decimal.new("0.05"))
      assert Decimal.equal?(weight, Decimal.new("1.5"))
    end

    test "maps an unrecognised status to :unknown" do
      assert {:ok, %Node{status: :unknown}} = Node.new(node_attrs(%{"status" => "bogus"}))
    end

    test "errors on missing fields" do
      assert {:error, :invalid_attrs} = Node.new(%{})
    end
  end

  describe "State.new/1" do
    test "parses minted, nodes aggregate and revenue" do
      assert {:ok,
              %State{
                minted: 5_000_000_000,
                nodes: %Nodes{
                  bond: 300_000_000,
                  capacity: 400_000_000,
                  nodes: [%Node{addr: "thor1node"}]
                },
                revenue: %Revenue{pending: 1_000_000, timestamp: %DateTime{}}
              } = state} = State.new(state_attrs())

      assert Decimal.equal?(state.nodes.weight, Decimal.new("2.5"))
      assert Decimal.equal?(state.revenue.fee_rate, Decimal.new("0.02"))
    end

    test "errors on missing fields" do
      assert {:error, :invalid_attrs} = State.new(%{})
    end

    test "propagates an invalid node in the aggregate" do
      assert {:error, :invalid_attrs} =
               State.new(
                 state_attrs(%{
                   "nodes" => %{
                     "bond" => "0",
                     "weight" => "0",
                     "capacity" => "0",
                     "nodes" => [%{}]
                   }
                 })
               )
    end
  end

  describe "load/1" do
    setup do
      Memoize.invalidate(State)
      on_exit(fn -> Memoize.invalidate(State) end)
      :ok
    end

    test "fills state from the scripted query" do
      MockNode.expect(fn %{"state" => %{}} -> MockNode.ok(state_attrs()) end)

      assert {:ok, %Pool{state: %State{minted: 5_000_000_000}}} =
               State.load(%Pool{address: "thor1pool"})
    end

    test "propagates a query failure" do
      MockNode.expect(fn _ -> {:error, %GRPC.RPCError{status: 2, message: "boom"}} end)

      assert {:error, %GRPC.RPCError{}} = State.load(%Pool{address: "thor1pool"})
    end
  end
end
