defmodule Rujira.Fin.PairTest do
  use ExUnit.Case, async: true

  alias Rujira.Fin.Pair
  alias Rujira.Deployments.Target

  describe "new/1 from map" do
    test "parses pair config with market_makers list" do
      config = %{
        "address" => "thor1pair",
        "market_makers" => ["thor1mm1", "thor1mm2"],
        "denoms" => ["gaia-atom", "eth-usdc-0xabc"],
        "oracles" => [
          %{"chain" => "GAIA", "symbol" => "ATOM"},
          %{"chain" => "ETH", "symbol" => "USDC"}
        ],
        "tick" => 6,
        "fee_taker" => "0.0015",
        "fee_maker" => "0.00075",
        "fee_address" => "thor1fee"
      }

      assert {:ok, %Pair{} = pair} = Pair.new(config)
      assert pair.address == "thor1pair"
      assert pair.id == "thor1pair"
      assert pair.market_makers == ["thor1mm1", "thor1mm2"]
      assert pair.token_base == "gaia-atom"
      assert pair.token_quote == "eth-usdc-0xabc"
      assert pair.tick == 6
      assert pair.fee_taker == Decimal.new("0.0015")
      assert pair.fee_maker == Decimal.new("0.00075")
      assert pair.fee_address == "thor1fee"
      assert pair.book == :not_loaded
      assert pair.summary == :not_loaded
      assert pair.deployment_status == :live
    end

    test "normalizes single market_maker to list" do
      config = %{
        "address" => "thor1pair",
        "market_maker" => "thor1mm",
        "denoms" => ["gaia-atom", "eth-usdc-0xabc"],
        "oracles" => nil,
        "tick" => 6,
        "fee_taker" => "0.0015",
        "fee_maker" => "0.00075",
        "fee_address" => "thor1fee"
      }

      assert {:ok, %Pair{market_makers: ["thor1mm"]}} = Pair.new(config)
    end

    test "normalizes nil market_maker to empty list" do
      config = %{
        "address" => "thor1pair",
        "market_maker" => nil,
        "denoms" => ["gaia-atom", "eth-usdc-0xabc"],
        "oracles" => nil,
        "tick" => 6,
        "fee_taker" => "0.0015",
        "fee_maker" => "0.00075",
        "fee_address" => "thor1fee"
      }

      assert {:ok, %Pair{market_makers: []}} = Pair.new(config)
    end
  end

  describe "new/1 from Target" do
    test "creates pair from deployment target" do
      target = %Target{
        address: "thor1pair",
        status: :preview,
        config: %{
          "denoms" => ["rune", "tcy"],
          "fee_address" => "thor1fee"
        }
      }

      assert {:ok, %Pair{} = pair} = Pair.new(target)
      assert pair.address == "thor1pair"
      assert pair.deployment_status == :preview
      assert pair.token_base == "rune"
      assert pair.token_quote == "tcy"
    end
  end

  describe "init_msg/1" do
    test "builds init message from config" do
      config = %{
        "denoms" => ["rune", "tcy"],
        "fee_address" => "thor1fee"
      }

      result = Pair.init_msg(config)
      assert result.denoms == ["rune", "tcy"]
      assert result.fee_taker == "0.0015"
      assert result.fee_maker == "0.00075"
      assert result.fee_address == "thor1fee"
      assert result.tick == 6
    end
  end

  describe "init_label/2" do
    test "generates label from denoms" do
      assert Pair.init_label("id", %{"denoms" => ["rune", "tcy"]}) == "rujira-fin:rune:tcy"
    end
  end

  describe "oracle_from_config/1" do
    test "parses map oracle" do
      assert {:ok, oracle} = Pair.oracle_from_config(%{"chain" => "GAIA", "symbol" => "ATOM"})
      assert oracle.id == "GAIA.ATOM"
      assert oracle.symbol == "GAIA.ATOM"
    end

    test "parses string oracle" do
      assert {:ok, oracle} = Pair.oracle_from_config("rune")
      assert oracle.id == "RUNE"
    end

    test "handles nil oracle" do
      assert {:ok, nil} = Pair.oracle_from_config(nil)
    end
  end
end
