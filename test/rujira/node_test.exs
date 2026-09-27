defmodule Rujira.NodeTest do
  use ExUnit.Case, async: true

  alias Rujira.Node
  alias Rujira.Test.MockNode

  @height 12_345
  @max_height 9_223_372_036_854_775_807

  describe "query/3 without :height" do
    test "forwards opts unchanged to the impl" do
      MockNode.expect(fn %{"a" => 1} -> MockNode.ok(%{"b" => 2}) end)

      assert {:ok, %{data: _}} = Node.query(& &1, %{"a" => 1}, foo: :bar)
      assert_received {:mock_node, %{"a" => 1}, [foo: :bar]}
    end
  end

  describe "query/3 with height: nil" do
    test "treats it as absent and does not forward the key" do
      MockNode.expect(fn %{"a" => 1} -> MockNode.ok(%{"b" => 2}) end)

      assert {:ok, %{data: _}} = Node.query(& &1, %{"a" => 1}, height: nil, foo: :bar)

      assert_received {:mock_node, %{"a" => 1}, opts}
      refute Keyword.has_key?(opts, :height)
      assert Keyword.get(opts, :foo) == :bar
    end
  end

  describe "query/3 with an invalid :height" do
    test "rejects a non-integer height without calling the impl" do
      assert {:error, :invalid_height} = Node.query(& &1, %{}, height: "12")
      refute_received {:mock_node, _, _}
    end

    test "rejects a height below 1 without calling the impl" do
      assert {:error, :invalid_height} = Node.query(& &1, %{}, height: 0)
      refute_received {:mock_node, _, _}
    end

    test "accepts the maximum valid height" do
      MockNode.expect(fn _ -> MockNode.ok(%{}) end)
      fun = fn _channel, _request, _opts -> {:ok, :reply} end

      assert {:ok, _} = Node.query(fun, %{}, height: @max_height)
    end

    test "rejects a height above the maximum without calling the impl" do
      assert {:error, :invalid_height} = Node.query(& &1, %{}, height: @max_height + 1)
      refute_received {:mock_node, _, _}
    end
  end

  describe "query/3 with a valid :height and an arity-2 fun" do
    test "returns :height_not_supported without calling the impl" do
      fun = fn _channel, _request -> {:ok, :reply} end

      assert {:error, :height_not_supported} = Node.query(fun, %{}, height: @height)
      refute_received {:mock_node, _, _}
    end
  end

  describe "query/3 with a valid :height and an arity-3 fun" do
    setup do
      fun = fn _channel, _request, _opts -> {:ok, :reply} end
      {:ok, fun: fun}
    end

    test "merges metadata and return_headers, keeping caller opts", %{fun: fun} do
      MockNode.expect(fn _ -> MockNode.ok(%{}) end)

      assert {:ok, %{data: _}} =
               Node.query(fun, %{}, height: @height, metadata: %{"x-caller" => "1"}, foo: :bar)

      assert_received {:mock_node, %{}, opts}
      assert Keyword.get(opts, :return_headers) == true
      assert Keyword.get(opts, :foo) == :bar

      assert Keyword.get(opts, :metadata) == %{
               "x-caller" => "1",
               "x-cosmos-block-height" => "12345"
             }
    end

    test "returns {:ok, reply} when the header map echoes the requested height", %{fun: fun} do
      MockNode.expect(fn _ -> MockNode.ok(%{"a" => 1}) end)

      assert {:ok, %{data: _}} = Node.query(fun, %{}, height: @height)
    end

    test "returns a height_mismatch error when the header list has a different height", %{
      fun: fun
    } do
      MockNode.expect(fn _ -> {:ok, :reply, %{headers: [{"x-cosmos-block-height", "999"}]}} end)

      assert {:error, {:height_mismatch, @height, 999}} = Node.query(fun, %{}, height: @height)
    end

    test "parses a header map for the mismatch", %{fun: fun} do
      MockNode.expect(fn _ ->
        {:ok, :reply, %{headers: %{"x-cosmos-block-height" => "999"}}}
      end)

      assert {:error, {:height_mismatch, @height, 999}} = Node.query(fun, %{}, height: @height)
    end

    test "returns a nil returned height when the header is missing", %{fun: fun} do
      MockNode.expect(fn _ -> {:ok, :reply, %{headers: %{}}} end)

      assert {:error, {:height_mismatch, @height, nil}} = Node.query(fun, %{}, height: @height)
    end

    test "returns a nil returned height when the header is not an integer", %{fun: fun} do
      MockNode.expect(fn _ ->
        {:ok, :reply, %{headers: %{"x-cosmos-block-height" => "not a height"}}}
      end)

      assert {:error, {:height_mismatch, @height, nil}} = Node.query(fun, %{}, height: @height)
    end

    test "returns a mismatch when the reply carries no headers key", %{fun: fun} do
      MockNode.expect(fn _ -> {:ok, :reply, %{trailers: %{}}} end)

      assert {:error, {:height_mismatch, @height, nil}} = Node.query(fun, %{}, height: @height)
    end

    test "maps a height-unavailable RPCError", %{fun: fun} do
      MockNode.expect(fn _ ->
        {:error, %GRPC.RPCError{status: 3, message: "Failed to load state at height 12345"}}
      end)

      assert {:error, {:height_unavailable, @height}} = Node.query(fun, %{}, height: @height)
    end

    test "leaves an unrelated RPCError unchanged", %{fun: fun} do
      MockNode.expect(fn _ ->
        {:error,
         %GRPC.RPCError{status: 3, message: "node is not persisting finalize block responses"}}
      end)

      assert {:error, %GRPC.RPCError{message: "node is not persisting finalize block responses"}} =
               Node.query(fun, %{}, height: @height)
    end
  end

  describe "height_unavailable?/1" do
    test "matches each documented pattern case-insensitively" do
      for message <- [
            "Cannot query with height in the future",
            "failed to load state at height 5",
            "height must be less than or equal to the current blockchain height",
            "pruning height is not available, lowest height is 100",
            "could not find results for height 5"
          ] do
        assert Node.height_unavailable?(%GRPC.RPCError{status: 3, message: message})
      end
    end

    test "does not match unrelated errors" do
      refute Node.height_unavailable?(%GRPC.RPCError{
               status: 3,
               message: "node is not persisting finalize block responses"
             })

      refute Node.height_unavailable?(:not_found)
    end
  end
end

defmodule Rujira.NodeDroppedHeadersTest do
  # Runs sync: it swaps the configured impl for one that drops the headers, which
  # `Rujira.Test.MockNode` cannot be scripted to do.
  use ExUnit.Case, async: false

  alias Rujira.Node

  defmodule DroppedHeaders do
    @moduledoc false
    @behaviour Rujira.Node

    @impl true
    def query(_fun, _request, _opts), do: {:ok, :reply}
  end

  @height 12_345

  setup do
    previous = Application.get_env(:rujira_ex, :node)
    Application.put_env(:rujira_ex, :node, DroppedHeaders)
    on_exit(fn -> Application.put_env(:rujira_ex, :node, previous) end)
    :ok
  end

  test "an impl that returns no headers at all is a mismatch with a nil returned height" do
    fun = fn _channel, _request, _opts -> {:ok, :reply} end

    assert {:error, {:height_mismatch, @height, nil}} = Node.query(fun, %{}, height: @height)
  end
end
