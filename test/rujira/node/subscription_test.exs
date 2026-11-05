defmodule Rujira.Node.SubscriptionTest do
  use ExUnit.Case, async: true

  # Tests within one module run one at a time, so the telemetry handler each
  # test attaches sees only its own subscriptions.
  @moduletag :capture_log

  import ExUnit.CaptureLog

  alias Rujira.Node.Subscription
  alias Rujira.Node.Subscription.Connection
  alias Rujira.Node.Subscription.Telemetry
  alias Rujira.Test.FakeWebSocket

  @fast [backoff_base: 10, backoff_max: 40, connect_timeout: 500, ping_interval: 60_000]

  setup context do
    name = Module.concat(__MODULE__, "S#{System.unique_integer([:positive])}")
    handler = "#{inspect(name)}-telemetry"
    :telemetry.attach_many(handler, Telemetry.events(), &__MODULE__.forward/4, self())

    on_exit(fn -> :telemetry.detach(handler) end)
    Map.put(context, :name, name)
  end

  def forward(event, measurements, metadata, test),
    do: send(test, {:telemetry, List.last(event), measurements, metadata})

  defp start!(name, url, opts \\ []) do
    spec = {Subscription, Keyword.merge(@fast, Keyword.merge(opts, url: url, name: name))}
    start_supervised!(Supervisor.child_spec(spec, id: name))
  end

  defp connection(name) do
    {_, pid, _, _} =
      name |> Supervisor.which_children() |> List.keyfind(Connection, 0)

    pid
  end

  defp subscribed!(gen \\ nil) do
    assert_receive {:fake_ws, :connected}, 1_000
    assert_receive {:fake_ws, :subscribe, id, "tm.event='NewBlockHeader'"}, 1_000
    if gen, do: assert(id == gen)
    assert_receive {:telemetry, :connect, %{attempt: _}, %{url: _}}, 1_000
    id
  end

  describe "without an endpoint" do
    test "subscribe/2 says so, and unsubscribe/2 is a no-op" do
      assert Rujira.Node.subscribe(:new_block) == {:error, :not_configured}
      assert Rujira.Node.unsubscribe(:new_block) == :ok
      assert Subscription.subscribe(:new_block, name: Nope) == {:error, :not_configured}
    end

    test "an unknown event is an error, never a crash" do
      assert Rujira.Node.subscribe(:new_tx) == {:error, :invalid_subscription}
      assert Rujira.Node.unsubscribe(:new_tx) == {:error, :invalid_subscription}
    end
  end

  describe "start_link/1" do
    test "refuses a URL that is not ws:// or wss://", %{name: name} do
      assert Subscription.start_link(url: "http://node:26657", name: name) ==
               {:error, {:invalid_url, "http://node:26657"}}

      assert Subscription.start_link(url: nil, name: name) == {:error, {:invalid_url, nil}}
    end
  end

  describe "subscribing" do
    test "sends the subscribe request and delivers each new block height", %{name: name} do
      {:ok, server, url} = FakeWebSocket.start()
      start!(name, url)

      assert Subscription.subscribe(:new_block, name: name) == :ok
      id = subscribed!()

      FakeWebSocket.send_text(server, FakeWebSocket.new_block(id, 28_446_896))
      assert_receive {:rujira_new_block, 28_446_896}, 1_000
      assert_receive {:telemetry, :new_block, %{height: 28_446_896, subscribers: 1}, _}
    end

    test "delivers heights ascending and each at most once", %{name: name} do
      {:ok, server, url} = FakeWebSocket.start()
      start!(name, url)
      :ok = Subscription.subscribe(:new_block, name: name)
      id = subscribed!()

      for h <- [10, 10, 9, 12],
          do: FakeWebSocket.send_text(server, FakeWebSocket.new_block(id, h))

      assert_receive {:rujira_new_block, 10}, 1_000
      assert_receive {:rujira_new_block, 12}, 1_000
      refute_received {:rujira_new_block, 9}
      refute_received {:rujira_new_block, 10}
    end

    test "subscribing twice delivers once; unsubscribe stops delivery", %{name: name} do
      {:ok, server, url} = FakeWebSocket.start()
      start!(name, url)
      :ok = Subscription.subscribe(:new_block, name: name)
      :ok = Subscription.subscribe(:new_block, name: name)
      id = subscribed!()

      FakeWebSocket.send_text(server, FakeWebSocket.new_block(id, 1))
      assert_receive {:rujira_new_block, 1}, 1_000
      refute_receive {:rujira_new_block, 1}, 50

      :ok = Subscription.unsubscribe(:new_block, name: name)
      FakeWebSocket.send_text(server, FakeWebSocket.new_block(id, 2))
      assert_receive {:telemetry, :new_block, %{height: 2, subscribers: 0}, _}, 1_000
      refute_received {:rujira_new_block, 2}
    end

    test "every subscriber receives the height; an exited one is dropped", %{name: name} do
      {:ok, server, url} = FakeWebSocket.start()
      start!(name, url)
      test = self()

      other =
        spawn(fn ->
          :ok = Subscription.subscribe(:new_block, name: name)
          send(test, :subscribed)
          receive do: ({:rujira_new_block, h} -> send(test, {:other, h}))
        end)

      assert_receive :subscribed
      :ok = Subscription.subscribe(:new_block, name: name)
      id = subscribed!()

      FakeWebSocket.send_text(server, FakeWebSocket.new_block(id, 5))
      assert_receive {:rujira_new_block, 5}, 1_000
      assert_receive {:other, 5}, 1_000

      ref = Process.monitor(other)
      assert_receive {:DOWN, ^ref, _, _, _}
      # The registry unregisters a dead process asynchronously.
      Process.sleep(20)

      FakeWebSocket.send_text(server, FakeWebSocket.new_block(id, 6))
      assert_receive {:telemetry, :new_block, %{height: 6, subscribers: 1}, _}, 1_000
    end

    test "the connection runs, and reconnects, before anyone subscribes", %{name: name} do
      {:ok, server, url} = FakeWebSocket.start()
      start!(name, url)
      id = subscribed!()

      FakeWebSocket.send_text(server, FakeWebSocket.new_block(id, 3))
      assert_receive {:telemetry, :new_block, %{height: 3, subscribers: 0}, _}, 1_000
    end
  end

  describe "malformed frames" do
    test "are skipped and reported, and the connection stays up", %{name: name} do
      {:ok, server, url} = FakeWebSocket.start()
      start!(name, url)
      :ok = Subscription.subscribe(:new_block, name: name)
      id = subscribed!()

      FakeWebSocket.send_text(server, "not json")
      FakeWebSocket.send_text(server, ~s({"jsonrpc":"2.0","id":#{id},"result":{"data":{}}}))
      FakeWebSocket.send_text(server, FakeWebSocket.new_block(id, "nope"))
      FakeWebSocket.send_text(server, FakeWebSocket.new_block(id, 0))
      FakeWebSocket.send_text(server, FakeWebSocket.new_block(id + 1_000, 7))
      FakeWebSocket.send_frame(server, 0x2, <<1, 2, 3>>)

      for _ <- 1..4,
          do:
            assert_receive(
              {:telemetry, :invalid_frame, %{count: 1}, %{reason: :invalid_message}},
              1_000
            )

      assert_receive {:telemetry, :invalid_frame, _,
                      %{reason: {:unexpected, {:new_block, _, 7}}}},
                     1_000

      assert_receive {:telemetry, :invalid_frame, _, %{reason: :binary_frame}}, 1_000

      FakeWebSocket.send_text(server, FakeWebSocket.new_block(id, 8))
      assert_receive {:rujira_new_block, 8}, 1_000
      refute_received {:rujira_new_block, 7}
      refute_received {:telemetry, :disconnect, _, _}
      assert FakeWebSocket.connections(server) == 1
    end
  end

  describe "reconnecting" do
    test "a dropped socket reconnects, resubscribes and keeps the subscribers", %{name: name} do
      {:ok, server, url} = FakeWebSocket.start()
      start!(name, url)
      :ok = Subscription.subscribe(:new_block, name: name)
      id = subscribed!()
      FakeWebSocket.send_text(server, FakeWebSocket.new_block(id, 100))
      assert_receive {:rujira_new_block, 100}, 1_000

      log =
        capture_log(fn ->
          FakeWebSocket.drop(server)

          assert_receive {:telemetry, :disconnect, %{attempt: 1, delay: delay}, %{reason: _}},
                         1_000

          assert delay in 5..10
          new_id = subscribed!()
          assert new_id != id

          # A reconnect can replay the header already sent; it is not sent twice.
          FakeWebSocket.send_text(server, FakeWebSocket.new_block(new_id, 100))
          FakeWebSocket.send_text(server, FakeWebSocket.new_block(new_id, 101))
          assert_receive {:rujira_new_block, 101}, 1_000
          refute_received {:rujira_new_block, 100}
        end)

      assert log =~ "no subscription at 127.0.0.1"
      assert FakeWebSocket.connections(server) == 2
    end

    test "a close frame from the node reconnects", %{name: name} do
      {:ok, server, url} = FakeWebSocket.start()
      start!(name, url)
      subscribed!()

      capture_log(fn ->
        FakeWebSocket.send_frame(server, 0x8, <<1000::16, "bye">>)
        assert_receive {:telemetry, :disconnect, _, %{reason: {:closed, 1000, "bye"}}}, 1_000
        subscribed!()
      end)
    end

    test "a refused subscription reconnects with a growing backoff", %{name: name} do
      {:ok, server, url} = FakeWebSocket.start(ack: false)
      start!(name, url)

      capture_log(fn ->
        assert_receive {:fake_ws, :subscribe, id, _}, 1_000

        FakeWebSocket.send_text(
          server,
          ~s({"jsonrpc":"2.0","id":#{id},"error":{"code":-32603,"message":"Internal error","data":"max_subscriptions_per_client 5 reached"}})
        )

        assert_receive {:telemetry, :disconnect, %{attempt: 1},
                        %{reason: {:rpc_error, %{"code" => -32603}}}},
                       1_000

        assert_receive {:fake_ws, :subscribe, id2, _}, 1_000
        assert id2 != id
        FakeWebSocket.send_text(server, ~s({"jsonrpc":"2.0","error":{"code":-32700}}))
        assert_receive {:telemetry, :disconnect, %{attempt: 2, delay: delay}, _}, 1_000
        assert delay in 10..20
      end)
    end

    test "a refused upgrade, an unreachable node or a silent one never crash anything", %{
      name: name
    } do
      {:ok, _server, url} = FakeWebSocket.start(handshake: {:status, 500})
      start!(name, url)
      :ok = Subscription.subscribe(:new_block, name: name)
      pid = connection(name)

      capture_log(fn ->
        assert_receive {:telemetry, :disconnect, %{attempt: 1}, _}, 1_000
        assert_receive {:telemetry, :disconnect, %{attempt: 2}, _}, 1_000
      end)

      assert connection(name) == pid

      {:ok, listen} = :gen_tcp.listen(0, ip: {127, 0, 0, 1})
      {:ok, port} = :inet.port(listen)
      :gen_tcp.close(listen)
      other = Module.concat(name, Down)

      capture_log(fn ->
        start!(other, "ws://127.0.0.1:#{port}/websocket")
        :ok = Subscription.subscribe(:new_block, name: other)
        assert_receive {:telemetry, :disconnect, %{attempt: 1}, %{reason: _}}, 1_000
        assert_receive {:telemetry, :disconnect, %{attempt: 2}, _}, 1_000
      end)

      {:ok, _silent, silent_url} = FakeWebSocket.start(handshake: :silent)
      silent = Module.concat(name, Silent)

      capture_log(fn ->
        start!(silent, silent_url, connect_timeout: 50)
        assert_receive {:telemetry, :disconnect, _, %{reason: :connect_timeout}}, 1_000
      end)
    end

    test "an unanswered ping drops the connection", %{name: name} do
      {:ok, _server, url} = FakeWebSocket.start(pong: false)
      start!(name, url, ping_interval: 30)
      subscribed!()

      capture_log(fn ->
        assert_receive {:fake_ws, :ping}, 1_000
        assert_receive {:telemetry, :disconnect, _, %{reason: :ping_timeout}}, 1_000
        subscribed!()
      end)
    end

    test "an answered ping keeps the connection", %{name: name} do
      {:ok, server, url} = FakeWebSocket.start()
      start!(name, url, ping_interval: 20)
      subscribed!()

      for _ <- 1..3, do: assert_receive({:fake_ws, :ping}, 1_000)
      refute_received {:telemetry, :disconnect, _, _}
      assert FakeWebSocket.connections(server) == 1
    end

    test "a ping from the node is answered", %{name: name} do
      {:ok, server, url} = FakeWebSocket.start()
      start!(name, url)
      subscribed!()

      FakeWebSocket.send_frame(server, 0x9, "hb")
      assert_receive {:fake_ws, :pong}, 1_000
    end

    test "a crashed connection is restarted and the subscribers kept", %{name: name} do
      {:ok, server, url} = FakeWebSocket.start()
      start!(name, url)
      :ok = Subscription.subscribe(:new_block, name: name)
      subscribed!()

      name |> connection() |> Process.exit(:kill)
      id = subscribed!()

      FakeWebSocket.send_text(server, FakeWebSocket.new_block(id, 42))
      assert_receive {:rujira_new_block, 42}, 1_000
    end
  end
end
