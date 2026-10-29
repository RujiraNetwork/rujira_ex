defmodule Rujira.Node.SubscriptionConfigTest do
  # Sets the application env and uses the default name: not async.
  use ExUnit.Case, async: false

  @moduletag :capture_log

  alias Rujira.Node.Subscription
  alias Rujira.Test.FakeWebSocket

  setup do
    on_exit(fn -> Application.delete_env(:rujira_ex, :websocket) end)
  end

  describe "from_config/0" do
    test "is nil without :websocket" do
      Application.delete_env(:rujira_ex, :websocket)
      assert Subscription.from_config() == nil
    end

    test "takes a URL or a keyword list" do
      Application.put_env(:rujira_ex, :websocket, "ws://thornode:27147/websocket")

      assert %{
               id: Subscription,
               start: {Subscription, :start_link, [[url: "ws://thornode:27147/websocket"]]}
             } =
               Subscription.from_config()

      Application.put_env(:rujira_ex, :websocket,
        url: "ws://thornode:27147",
        ping_interval: 5_000
      )

      assert %{
               start:
                 {Subscription, :start_link, [[url: "ws://thornode:27147", ping_interval: 5_000]]}
             } =
               Subscription.from_config()
    end
  end

  test "Rujira.Node.subscribe/2 reaches the subscription under the default name" do
    {:ok, server, url} = FakeWebSocket.start()
    start_supervised!(Subscription.from_config() || {Subscription, url: url})

    assert Rujira.Node.subscribe(:new_block) == :ok
    assert_receive {:fake_ws, :subscribe, id, _}, 1_000

    FakeWebSocket.send_text(server, FakeWebSocket.new_block(id, 9))
    assert_receive {:rujira_new_block, 9}, 1_000

    assert Rujira.Node.unsubscribe(:new_block) == :ok
    FakeWebSocket.send_text(server, FakeWebSocket.new_block(id, 10))
    refute_receive {:rujira_new_block, 10}, 100
  end
end
