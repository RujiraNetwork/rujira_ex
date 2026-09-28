defmodule Rujira.Fin.SimulationTest do
  @moduledoc """
  A simulation is read through `Rujira.Cache`, whose stores and head are
  global, so this case runs sync and starts from an empty cache.
  """
  use Rujira.Test.CacheCase, async: false

  alias Rujira.Assets
  alias Rujira.Coin
  alias Rujira.Fin.Pair
  alias Rujira.Fin.Simulation
  alias Rujira.Test.MockNode

  @height 500
  @metadata %{"x-cosmos-block-height" => "500"}

  @pair %Pair{
    address: "thor1pair",
    asset_base: elem(Assets.from_denom("btc-btc"), 1),
    asset_quote: elem(Assets.from_denom("rune"), 1)
  }

  describe "simulate/2" do
    test "parses the simulate response into a struct, returned/fee in the ask token" do
      MockNode.expect(fn
        %{"simulate" => %{"denom" => "btc-btc", "amount" => "1000"}} ->
          MockNode.ok(%{"returned" => "990", "fee" => "10"})
      end)

      {:ok, btc} = Assets.from_denom("btc-btc")
      offer = Coin.new(btc, 1000)

      assert {:ok, %Simulation{} = simulation} = Simulation.simulate(@pair, offer)

      assert simulation.id == "thor1pair:btc-btc:1000"
      assert simulation.pair == "thor1pair"
      assert simulation.offer == offer
      assert {:ok, "rune"} = Assets.to_native(simulation.returned.asset)
      assert simulation.returned.amount == 990
      assert {:ok, "rune"} = Assets.to_native(simulation.fee.asset)
      assert simulation.fee.amount == 10
    end

    test "resolves the pair by address" do
      MockNode.expect(fn
        %{"config" => %{}} -> respond_pair()
        %{"simulate" => _} -> MockNode.ok(%{"returned" => "500", "fee" => "5"})
      end)

      {:ok, rune} = Assets.from_denom("rune")
      offer = Coin.new(rune, 1000)

      assert {:ok, %Simulation{pair: "thor1pair"}} = Simulation.simulate("thor1pair", offer)
    end

    test "an offer token not in the pair returns :invalid_offer" do
      {:ok, tcy} = Assets.from_denom("tcy")
      offer = Coin.new(tcy, 1000)

      assert {:error, :invalid_offer} = Simulation.simulate(@pair, offer)
    end

    test "sends the exact query map expected by the contract" do
      test_pid = self()

      MockNode.expect(fn query ->
        send(test_pid, {:query, query})
        MockNode.ok(%{"returned" => "0", "fee" => "0"})
      end)

      {:ok, btc} = Assets.from_denom("btc-btc")
      Simulation.simulate(@pair, Coin.new(btc, 500))

      assert_received {:query, %{"simulate" => %{"denom" => "btc-btc", "amount" => "500"}}}
    end

    test "returns error on invalid response" do
      MockNode.expect(fn _ -> MockNode.ok(%{"unexpected" => "shape"}) end)

      {:ok, btc} = Assets.from_denom("btc-btc")

      assert {:error, :invalid_attrs} = Simulation.simulate(@pair, Coin.new(btc, 3000))
    end
  end

  describe "query/4" do
    test "a height read carries the block-height metadata into the simulate query" do
      MockNode.expect(fn %{"simulate" => _} ->
        MockNode.ok(%{"returned" => "1", "fee" => "0"})
      end)

      {:ok, btc} = Assets.from_denom("btc-btc")

      assert {:ok, _} = Simulation.query("thor1pair", btc, 1000, height: @height)
      assert_received {:mock_node, _request, opts}
      assert Keyword.get(opts, :metadata) == @metadata
    end

    test "a second read at the same height is served from the cache" do
      MockNode.expect(fn %{"simulate" => _} ->
        MockNode.ok(%{"returned" => "1", "fee" => "0"})
      end)

      {:ok, btc} = Assets.from_denom("btc-btc")

      assert {:ok, _} = Simulation.query("thor1pair", btc, 1000, height: @height)
      assert {:ok, _} = Simulation.query("thor1pair", btc, 1000, height: @height)

      assert_received {:mock_node, _, _}
      refute_received {:mock_node, _, _}
    end

    test "the asset is keyed by its native denom, not by the struct it arrived in" do
      MockNode.expect(fn %{"simulate" => _} ->
        MockNode.ok(%{"returned" => "1", "fee" => "0"})
      end)

      {:ok, btc} = Assets.from_denom("btc-btc")

      assert {:ok, _} = Simulation.query("thor1pair", btc, 1000, height: @height)

      assert {:ok, _} =
               Simulation.query("thor1pair", %{btc | metadata: :not_loaded}, 1000,
                 height: @height
               )

      assert_received {:mock_node, _, _}
      refute_received {:mock_node, _, _}
    end

    test "a simulation is only the simulation of its own height" do
      MockNode.expect(fn %{"simulate" => _} ->
        MockNode.ok(%{"returned" => "1", "fee" => "0"})
      end)

      {:ok, btc} = Assets.from_denom("btc-btc")

      assert {:ok, _} = Simulation.query("thor1pair", btc, 1000, height: @height)
      assert {:ok, _} = Simulation.query("thor1pair", btc, 1000, height: @height - 1)

      assert_received {:mock_node, _, _}
      assert_received {:mock_node, _, _}
    end

    test "an error is never cached, so the next read retries it" do
      MockNode.expect(fn %{"simulate" => _} ->
        {:error, %GRPC.RPCError{status: 13, message: "boom"}}
      end)

      {:ok, btc} = Assets.from_denom("btc-btc")

      assert {:error, %GRPC.RPCError{}} =
               Simulation.query("thor1pair", btc, 1000, height: @height)

      MockNode.expect(fn %{"simulate" => _} ->
        MockNode.ok(%{"returned" => "1", "fee" => "0"})
      end)

      assert {:ok, _} = Simulation.query("thor1pair", btc, 1000, height: @height)
    end

    test "a heightless read is at the head, and has none before the first advance" do
      MockNode.expect(fn %{"simulate" => _} ->
        MockNode.ok(%{"returned" => "1", "fee" => "0"})
      end)

      {:ok, btc} = Assets.from_denom("btc-btc")

      assert {:ok, _} = Simulation.query("thor1pair", btc, 1000)

      reset_cache()
      assert {:error, :no_head} = Simulation.query("thor1pair", btc, 1000)
    end
  end

  describe "from_id/1" do
    test "parses id and simulates" do
      MockNode.expect(fn
        %{"config" => %{}} ->
          respond_pair()

        %{"simulate" => %{"denom" => "btc-btc", "amount" => "2000"}} ->
          MockNode.ok(%{"returned" => "1980", "fee" => "20"})
      end)

      assert {:ok, %Simulation{} = simulation} =
               Simulation.from_id("thor1pair:btc-btc:2000")

      assert simulation.pair == "thor1pair"
      assert simulation.offer.amount == 2000
      assert simulation.returned.amount == 1980
      assert simulation.fee.amount == 20
    end

    test "rejects a malformed id" do
      assert {:error, :invalid_id} = Simulation.from_id("thor1pair:btc-btc")
      assert {:error, :invalid_id} = Simulation.from_id("thor1pair:btc-btc:not-a-number")
    end
  end

  defp respond_pair do
    MockNode.ok(%{
      "address" => "thor1pair",
      "market_maker" => nil,
      "denoms" => ["btc-btc", "rune"],
      "oracles" => [],
      "tick" => 1,
      "fee_taker" => "0.01",
      "fee_maker" => "0.01",
      "fee_address" => "thor1fee"
    })
  end
end
