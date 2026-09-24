defmodule Rujira.Brune.LoggedEventTest do
  use ExUnit.Case, async: true

  alias Rujira.Brune.Events.Event, as: BruneEvent
  alias Rujira.Brune.Events.NodeBond
  alias Rujira.Brune.LoggedEvent
  alias Rujira.Test.MockNode

  defp raw_event(extra \\ %{}) do
    Map.merge(
      %{
        "id" => 42,
        "time" => "1700000000000000000",
        "height" => 12_345,
        "event" => %{
          "type" => "rujira-brune/node.bond",
          "attributes" => [
            %{"key" => "node", "value" => "thor1node"},
            %{"key" => "amount", "value" => "100"}
          ]
        }
      },
      extra
    )
  end

  describe "new/2" do
    test "normalises the stored event and parses it like a live one" do
      assert {:ok,
              %LoggedEvent{
                id: 42,
                height: 12_345,
                time: %DateTime{},
                event: %BruneEvent{
                  address: "thor1pool",
                  data: %NodeBond{node: "thor1node", amount: 100}
                }
              }} = LoggedEvent.new(raw_event(), "thor1pool")
    end

    test "errors on missing fields" do
      assert {:error, :invalid_attrs} = LoggedEvent.new(%{}, "thor1pool")
    end
  end

  describe "list/3" do
    test "fetches and parses one page, newest first" do
      MockNode.expect(fn %{"events" => %{"start_after" => nil, "limit" => 100}} ->
        MockNode.ok(%{"events" => [raw_event(), raw_event(%{"id" => 41})]})
      end)

      assert {:ok, [%LoggedEvent{id: 42}, %LoggedEvent{id: 41}]} =
               LoggedEvent.list("thor1pool")
    end

    test "passes start_after and limit through to the query" do
      MockNode.expect(fn %{"events" => %{"start_after" => 41, "limit" => 10}} ->
        MockNode.ok(%{"events" => []})
      end)

      assert {:ok, []} = LoggedEvent.list("thor1pool", 41, 10)
    end

    test "propagates a query failure" do
      MockNode.expect(fn _ -> {:error, %GRPC.RPCError{status: 2, message: "boom"}} end)

      assert {:error, %GRPC.RPCError{}} = LoggedEvent.list("thor1pool")
    end
  end
end
