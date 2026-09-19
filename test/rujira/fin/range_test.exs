defmodule Rujira.Fin.RangeTest do
  use ExUnit.Case, async: true

  alias Rujira.Fin.Range
  alias Rujira.Fin.Range.Dynamic
  alias Rujira.Fin.Range.Dynamic.Params
  alias Rujira.Fin.Range.Fixed
  alias Rujira.Test.MockNode

  @pair %{
    address: "thor1pair",
    token_quote: "eth-usdc-0xabc",
    token_base: "gaia-atom"
  }

  describe "new/2" do
    test "parses the fixed arm of the response union" do
      attrs = %{
        "idx" => "5",
        "owner" => "thor1owner",
        "high" => "2.0",
        "low" => "1.0",
        "skew" => "-0.1",
        "spread" => "0.01",
        "fee" => "0.003",
        "base" => "1000",
        "quote" => "2000",
        "price" => "1.5",
        "ask" => "1.52",
        "bid" => "1.48",
        "fees" => ["10", "20"]
      }

      assert {:ok, %Range{} = range} = Range.new(@pair, attrs)
      assert range.id == "thor1pair/5"
      assert range.idx == 5
      assert range.pair == "thor1pair"
      assert range.owner == "thor1owner"

      assert %Fixed{base: 1000, quote: 2000, fees_base: 10, fees_quote: 20} = range.range
      assert Decimal.equal?(range.range.high, Decimal.new("2.0"))
      assert Decimal.equal?(range.range.skew, Decimal.new("-0.1"))
      assert Decimal.equal?(range.range.price, Decimal.new("1.5"))
    end

    test "parses the dynamic arm, whose params arrive flattened" do
      attrs = %{
        "idx" => "9",
        "owner" => "thor1owner",
        "min_profit" => "0.01",
        "claimable_share" => "0.5",
        "bid_depth" => "0.1",
        "ask_depth" => "0.2",
        "skew" => "1.5",
        "reanchor_aep_on_sellout" => true,
        "base" => "1000",
        "quote" => "2000",
        "claimable_base" => "10",
        "claimable_quote" => "20",
        "cost_basis" => "100000",
        "aep" => "100"
      }

      assert {:ok, %Range{} = range} = Range.new(@pair, attrs)
      assert range.id == "thor1pair/9"
      assert range.idx == 9
      assert range.owner == "thor1owner"

      assert %Dynamic{base: 1000, quote: 2000, claimable_base: 10, claimable_quote: 20} =
               range.range

      assert Decimal.equal?(range.range.aep, Decimal.new("100"))
      assert Decimal.equal?(range.range.cost_basis, Decimal.new("100000"))

      assert %Params{reanchor_aep_on_sellout: true} = range.range.params
      assert Decimal.equal?(range.range.params.min_profit, Decimal.new("0.01"))
      assert Decimal.equal?(range.range.params.skew, Decimal.new("1.5"))
    end

    test "accepts reanchor_aep_on_sellout as a string, as events encode it" do
      assert {:ok, %Params{reanchor_aep_on_sellout: false}} =
               Params.new(%{
                 "min_profit" => "0",
                 "claimable_share" => "0",
                 "bid_depth" => "0",
                 "ask_depth" => "0",
                 "skew" => "1",
                 "reanchor_aep_on_sellout" => "false"
               })
    end

    test "an unrecognised response shape is an error, not a raise" do
      assert {:error, :invalid_attrs} = Range.new(@pair, %{"idx" => "1", "owner" => "thor1owner"})
    end
  end

  describe "list/3 against a deployment that predates dynamic ranges" do
    setup do
      # `query_ranges`/`query_dynamic_ranges` are memoized on (contract, owner).
      Memoize.invalidate(Rujira.Fin.Range)
      on_exit(fn -> Memoize.invalidate(Rujira.Fin.Range) end)
      :ok
    end

    test "falls back to the fixed ranges instead of failing" do
      MockNode.expect(fn
        # A pre-DCL FIN build cannot deserialize the `dynamic` variant.
        %{"ranges" => %{"dynamic" => _}} ->
          {:error, parse_error()}

        %{"ranges" => _} ->
          MockNode.ok(%{"ranges" => [fixed_response()]})
      end)

      assert {:ok, [%Range{idx: 5, range: %Fixed{}}]} = Range.list(@pair)
    end

    test "a genuine failure on the dynamic arm still propagates" do
      MockNode.expect(fn
        %{"ranges" => %{"dynamic" => _}} ->
          {:error, not_found()}

        %{"ranges" => _} ->
          MockNode.ok(%{"ranges" => [fixed_response()]})
      end)

      assert {:error, %GRPC.RPCError{message: "NotFound: query wasm contract failed"}} =
               Range.list(@pair)
    end

    test "both arms are returned when the deployment understands them" do
      MockNode.expect(fn
        %{"ranges" => %{"dynamic" => _}} -> MockNode.ok(%{"ranges" => [dynamic_response()]})
        %{"ranges" => _} -> MockNode.ok(%{"ranges" => [fixed_response()]})
      end)

      assert {:ok, [%Range{idx: 5, range: %Fixed{}}, %Range{idx: 9, range: %Dynamic{}}]} =
               Range.list(@pair)
    end

    test "load/2 returns a placeholder rather than failing" do
      MockNode.expect(fn
        %{"range" => %{"dynamic" => _}} -> {:error, parse_error()}
        %{"range" => _} -> {:error, not_found()}
      end)

      assert {:ok, %Range{id: "thor1pair/5", idx: 5, range: nil}} = Range.load(@pair, 5)
    end

    test "load/2 still finds a dynamic range on a migrated deployment" do
      MockNode.expect(fn
        %{"range" => %{"dynamic" => _}} -> MockNode.ok(dynamic_response())
        %{"range" => _} -> {:error, not_found()}
      end)

      assert {:ok, %Range{idx: 9, range: %Dynamic{}}} = Range.load(@pair, 9)
    end
  end

  describe "totals/1" do
    test "a fixed range counts uncollected fees" do
      assert {1010, 2020} =
               Fixed.totals(%Fixed{base: 1000, quote: 2000, fees_base: 10, fees_quote: 20})
    end

    test "a dynamic range counts segregated profit" do
      assert {1010, 2020} =
               Dynamic.totals(%Dynamic{
                 base: 1000,
                 quote: 2000,
                 claimable_base: 10,
                 claimable_quote: 20
               })
    end
  end

  # --- Fixtures ---

  defp parse_error do
    %GRPC.RPCError{
      status: 2,
      message:
        "Error parsing into type rujira_fin::msg::QueryMsg: unknown field `dynamic`, " <>
          "expected one of `owner`, `cursor`, `limit`: query wasm contract failed"
    }
  end

  defp not_found do
    %GRPC.RPCError{status: 2, message: "NotFound: query wasm contract failed"}
  end

  defp fixed_response do
    %{
      "idx" => "5",
      "owner" => "thor1owner",
      "high" => "2.0",
      "low" => "1.0",
      "skew" => "-0.1",
      "spread" => "0.01",
      "fee" => "0.003",
      "base" => "1000",
      "quote" => "2000",
      "price" => "1.5",
      "ask" => "1.52",
      "bid" => "1.48",
      "fees" => ["10", "20"]
    }
  end

  defp dynamic_response do
    %{
      "idx" => "9",
      "owner" => "thor1owner",
      "min_profit" => "0.01",
      "claimable_share" => "0.5",
      "bid_depth" => "0.1",
      "ask_depth" => "0.2",
      "skew" => "1.5",
      "reanchor_aep_on_sellout" => true,
      "base" => "1000",
      "quote" => "2000",
      "claimable_base" => "10",
      "claimable_quote" => "20",
      "cost_basis" => "100000",
      "aep" => "100"
    }
  end
end
