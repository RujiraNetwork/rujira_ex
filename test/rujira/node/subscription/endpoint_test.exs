defmodule Rujira.Node.Subscription.EndpointTest do
  use ExUnit.Case, async: true

  alias Rujira.Node.Subscription.Endpoint

  test "parses ws:// and wss:// URLs" do
    assert {:ok, %Endpoint{scheme: :ws, host: "thornode", port: 27_147, path: "/websocket"} = ws} =
             Endpoint.new("ws://thornode:27147/websocket")

    assert Endpoint.http_scheme(ws) == :http

    assert {:ok,
            %Endpoint{scheme: :wss, host: "rpc.example", port: 443, path: "/chain/ws?k=1"} = wss} =
             Endpoint.new("wss://rpc.example/chain/ws?k=1")

    assert Endpoint.http_scheme(wss) == :https
  end

  test "defaults the path to /websocket" do
    assert {:ok, %Endpoint{port: 80, path: "/websocket"}} = Endpoint.new("ws://thornode")
    assert {:ok, %Endpoint{path: "/websocket"}} = Endpoint.new("ws://thornode:27147/")
  end

  test "refuses anything else" do
    for url <- ["http://thornode:27147", "thornode:27147", "ws://", "ws:///websocket", "", nil, 1] do
      assert Endpoint.new(url) == {:error, {:invalid_url, url}}
    end
  end
end
