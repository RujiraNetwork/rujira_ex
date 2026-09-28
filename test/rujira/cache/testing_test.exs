defmodule Rujira.Cache.TestingTest do
  @moduledoc """
  `Rujira.Cache.Testing`: the head a consumer's own test suite sets up.
  """
  use ExUnit.Case, async: false

  alias Rujira.Cache
  alias Rujira.Cache.Testing
  alias Rujira.Test.MockNode
  alias Thorchain.Types.QueryBlockRequest

  setup do
    on_exit(&Rujira.Test.CacheCase.reset!/0)
    :ok
  end

  test "reset! leaves no head, so a heightless read says so" do
    assert :ok = Testing.reset!()

    assert Cache.head() == nil

    assert {:error, :no_head} =
             Cache.fetch({__MODULE__, :thing, []}, [:per_block], [], fn _h ->
               {:ok, 1}
             end)
  end

  test "set_head puts a head there without fetching a block" do
    fetched = no_blocks()

    assert :ok = Testing.reset!()
    assert :ok = Testing.set_head(4_000_000)

    assert Cache.head() == 4_000_000
    assert :counters.get(fetched, 1) == 0
  end

  test "set_head one height at a time fetches nothing either" do
    fetched = no_blocks()

    assert :ok = Testing.reset!()
    assert :ok = Testing.set_head(4_100_000)
    assert :ok = Testing.set_head(4_100_001)

    assert Cache.head() == 4_100_001
    assert :counters.get(fetched, 1) == 0
  end

  test "set_head invalidates nothing already cached" do
    assert :ok = Testing.reset!()
    assert :ok = Testing.set_head(4_200_000)

    key = {__MODULE__, :thing, []}
    sources = [{:contract, "thor1a"}]

    assert {:ok, 1} = Cache.fetch(key, sources, [], fn _height -> {:ok, 1} end)
    assert :ok = Testing.set_head(4_200_001)
    assert {:ok, 1} = Cache.fetch(key, sources, [], fn _height -> {:ok, 2} end)
  end

  # --- Fixtures ---

  # Counts the blocks the node is asked for, so a test can prove there were none.
  defp no_blocks do
    counter = :counters.new(1, [])

    MockNode.expect(fn %QueryBlockRequest{} ->
      :counters.add(counter, 1, 1)
      {:error, :should_not_be_fetched}
    end)

    counter
  end
end
