defmodule Rujira.HeightErrorsTest do
  @moduledoc """
  A read at a height either answers with the state at that height or says it
  could not. Every function here used to answer a failed height read with a
  default - an empty book, a zero account, a skipped pair, a zero TVL - and now
  hands the height error back instead, while keeping that default for every
  other error.
  """
  use ExUnit.Case, async: false

  alias Rujira.Deployments
  alias Rujira.Fin
  alias Rujira.Fin.Book
  alias Rujira.Fin.Pair
  alias Rujira.Ghost
  alias Rujira.Ghost.Vault
  alias Rujira.Ghost.Vault.Account
  alias Rujira.Test.MockNode
  alias Thorchain.Types.ContractInfo
  alias Thorchain.Types.QueryContractInfosRequest

  @height 500
  @unavailable %GRPC.RPCError{
    status: 2,
    message: "failed to load state at height 500: query wasm contract failed"
  }
  @other %GRPC.RPCError{status: 2, message: "boom: query wasm contract failed"}

  defmodule LegacyMarketMaker do
    @moduledoc "A market maker module that predates `opts` - bare arities only."

    @spec pool_from_id(String.t()) :: {:ok, map()}
    def pool_from_id(id) do
      Process.put(:legacy_mm_called, true)
      {:ok, %{id: id}}
    end

    @spec tvl(map()) :: integer()
    def tvl(_pool), do: 4200
  end

  defmodule ModernMarketMaker do
    @moduledoc "A market maker module that takes opts, but fails its own read at height."

    @spec pool_from_id(String.t(), Rujira.Node.opts()) :: {:ok, map()} | {:error, term()}
    def pool_from_id(id, opts) do
      case Keyword.get(opts, :height) do
        nil -> {:ok, %{id: id}}
        height -> {:error, {:height_unavailable, height}}
      end
    end

    @spec tvl(map(), Rujira.Node.opts()) :: integer()
    def tvl(_pool, _opts), do: 4200
  end

  defmodule FailingMarketMaker do
    @moduledoc "A market maker whose own read fails for a reason other than height."

    @spec pool_from_id(String.t(), Rujira.Node.opts()) :: {:error, :boom}
    def pool_from_id(_id, _opts), do: {:error, :boom}

    @spec tvl(map(), Rujira.Node.opts()) :: integer()
    def tvl(_pool, _opts), do: 4200
  end

  setup do
    original = Application.get_env(:rujira_ex, :protocol_modules)

    on_exit(fn ->
      if original do
        Application.put_env(:rujira_ex, :protocol_modules, original)
      else
        Application.delete_env(:rujira_ex, :protocol_modules)
      end

      Memoize.invalidate()
    end)

    Memoize.invalidate()
    :ok
  end

  describe "Fin.load_pair/3 (Book.load/3)" do
    test "hands back the height error rather than an empty book" do
      MockNode.expect(fn %{"book" => _} -> {:error, @unavailable} end)

      assert {:error, {:height_unavailable, @height}} =
               Fin.load_pair(pair(), 75, height: @height)
    end

    test "rejects an unusable height before the node is touched" do
      MockNode.expect(fn %{"book" => _} -> MockNode.ok(%{"base" => [], "quote" => []}) end)

      assert {:error, :invalid_height} = Fin.load_pair(pair(), 75, height: 0)
    end

    test "still answers with an empty book for any other error" do
      MockNode.expect(fn %{"book" => _} -> {:error, @other} end)

      assert {:ok, %Pair{book: %Book{id: "thor1pair", bids: [], asks: []}}} =
               Fin.load_pair(pair(), 75)
    end
  end

  describe "Fin.get_pair_tvl/2 (Pair.tvl/2)" do
    test "hands back the height error rather than a zero TVL" do
      MockNode.expect(fn %{"config" => _} -> {:error, @unavailable} end)

      assert {:error, {:height_unavailable, @height}} =
               Fin.get_pair_tvl("thor1pair", height: @height)
    end

    test "still answers zero for any other error" do
      MockNode.expect(fn %{"config" => _} -> {:error, @other} end)

      assert {:ok, 0} = Fin.get_pair_tvl("thor1pair")
    end
  end

  describe "Deployments.list_targets/2 and get_target/2" do
    test "list_targets/2 hands back the height error rather than an empty list" do
      MockNode.expect(fn %QueryContractInfosRequest{} -> {:error, @unavailable} end)

      assert {:error, {:height_unavailable, @height}} =
               Deployments.list_targets(Pair, height: @height)
    end

    test "get_target/2 hands back the height error rather than nil" do
      MockNode.expect(fn %QueryContractInfosRequest{} -> {:error, @unavailable} end)

      assert {:error, {:height_unavailable, @height}} =
               Deployments.get_target(Pair, height: @height)
    end
  end

  describe "Fin.list_pairs/1 (Pair.fetch_list/1)" do
    test "hands back the height error rather than skipping the pair" do
      MockNode.expect(fn
        %QueryContractInfosRequest{} -> {:ok, %{infos: [fin_info()]}}
        %{"config" => _} -> {:error, @unavailable}
      end)

      assert {:error, {:height_unavailable, @height}} = Fin.list_pairs(height: @height)
    end

    test "still skips a pair that fails for any other reason" do
      MockNode.expect(fn
        %QueryContractInfosRequest{} -> {:ok, %{infos: [fin_info()]}}
        %{"config" => _} -> {:error, @other}
      end)

      assert {:ok, []} = Fin.list_pairs()
    end
  end

  describe "Fin.pair_from_id/2 (Pair.lookup/2)" do
    test "hands back the height error rather than calling the id invalid" do
      MockNode.expect(fn
        %QueryContractInfosRequest{} -> {:ok, %{infos: [fin_info()]}}
        %{"config" => _} -> {:error, @unavailable}
      end)

      assert {:error, {:height_unavailable, @height}} =
               Fin.pair_from_id("atom/usdc", height: @height)
    end

    test "still calls a malformed id invalid, and a missing pair not found" do
      MockNode.expect(fn
        %QueryContractInfosRequest{} -> {:ok, %{infos: [fin_info()]}}
        %{"config" => _} -> {:error, @other}
      end)

      assert {:error, :invalid_id} = Fin.pair_from_id("atom/usdc/extra")
      assert {:error, :not_found} = Fin.pair_from_id("atom/usdc")
    end
  end

  describe "Fin.total_range_tvl/1 (Range.tvl_or_zero/2)" do
    test "hands back the height error rather than zeroing the pair out of the total" do
      MockNode.expect(fn
        %QueryContractInfosRequest{} -> {:ok, %{infos: [fin_info()]}}
        %{"config" => _} -> MockNode.ok(pair_config())
        %{"ranges" => _} -> {:error, @unavailable}
      end)

      assert {:error, {:height_unavailable, @height}} = Fin.total_range_tvl(height: @height)
    end

    test "still leaves a pair that fails for any other reason out of the total" do
      MockNode.expect(fn
        %QueryContractInfosRequest{} -> {:ok, %{infos: [fin_info()]}}
        %{"config" => _} -> MockNode.ok(pair_config())
        %{"ranges" => _} -> {:error, @other}
      end)

      assert {:ok, 0} = Fin.total_range_tvl()
    end
  end

  describe "Ghost.list_vaults/1 (Vault.list/1)" do
    test "hands back the height error rather than an empty list" do
      MockNode.expect(fn %QueryContractInfosRequest{} -> {:error, @unavailable} end)

      assert {:error, {:height_unavailable, @height}} = Ghost.list_vaults(height: @height)
    end
  end

  describe "Ghost.load_vault_account/3 (Account.load/3)" do
    test "hands back the height error rather than a zero account" do
      MockNode.expect(fn %{"status" => _} -> {:error, @unavailable} end)

      assert {:error, {:height_unavailable, @height}} =
               Ghost.load_vault_account(vault(), "thor1acc", height: @height)
    end

    test "still answers a zero account for any other error" do
      MockNode.expect(fn %{"status" => _} -> {:error, @other} end)

      assert {:ok, %Account{shares: 0, value: 0}} =
               Ghost.load_vault_account(vault(), "thor1acc")
    end
  end

  describe "Fin.get_pair_tvl/2 (Pair.mm_tvl/2 propagation)" do
    test "hands back the from_address height error rather than a partial TVL" do
      Application.put_env(:rujira_ex, :protocol_modules, %{"legacy-mm" => LegacyMarketMaker})
      Memoize.invalidate()

      MockNode.expect(fn
        %QueryContractInfosRequest{} -> {:error, @unavailable}
        %{"config" => _} -> MockNode.ok(pair_config(["thor1mm"]))
      end)

      assert {:error, {:height_unavailable, @height}} =
               Fin.get_pair_tvl("thor1pair", height: @height)
    end

    test "hands back a market maker's own height error rather than a partial TVL" do
      Application.put_env(:rujira_ex, :protocol_modules, %{"modern-mm" => ModernMarketMaker})
      Memoize.invalidate()

      MockNode.expect(fn
        %QueryContractInfosRequest{} -> {:ok, %{infos: [fin_info(), modern_mm_info()]}}
        %{"config" => _} -> MockNode.ok(pair_config(["thor1mm"]))
      end)

      assert {:error, {:height_unavailable, @height}} =
               Fin.get_pair_tvl("thor1pair", height: @height)
    end

    test "an unconverted market maker's height read is refused, not silently zeroed" do
      Application.put_env(:rujira_ex, :protocol_modules, %{"legacy-mm" => LegacyMarketMaker})
      Memoize.invalidate()
      Process.delete(:legacy_mm_called)

      MockNode.expect(fn
        %QueryContractInfosRequest{} -> {:ok, %{infos: [fin_info(), mm_info()]}}
        %{"config" => _} -> MockNode.ok(pair_config(["thor1mm"]))
        %{"ranges" => _} -> MockNode.ok(%{"ranges" => []})
      end)

      assert {:error, :height_not_supported} = Fin.get_pair_tvl("thor1pair", height: @height)
      refute Process.get(:legacy_mm_called)
    end

    test "a live read still falls back to the bare arity" do
      Application.put_env(:rujira_ex, :protocol_modules, %{"legacy-mm" => LegacyMarketMaker})
      Memoize.invalidate()
      Process.delete(:legacy_mm_called)

      MockNode.expect(fn
        %QueryContractInfosRequest{} -> {:ok, %{infos: [fin_info(), mm_info()]}}
        %{"config" => _} -> MockNode.ok(pair_config(["thor1mm"]))
        %{"ranges" => _} -> MockNode.ok(%{"ranges" => []})
      end)

      assert {:ok, 4200} = Fin.get_pair_tvl("thor1pair")
      assert Process.get(:legacy_mm_called)
    end

    test "still contributes zero for a market maker error that is not about height" do
      Application.put_env(:rujira_ex, :protocol_modules, %{"failing-mm" => FailingMarketMaker})
      Memoize.invalidate()

      MockNode.expect(fn
        %QueryContractInfosRequest{} -> {:ok, %{infos: [fin_info(), failing_mm_info()]}}
        %{"config" => _} -> MockNode.ok(pair_config(["thor1mm"]))
        %{"ranges" => _} -> MockNode.ok(%{"ranges" => []})
      end)

      assert {:ok, 0} = Fin.get_pair_tvl("thor1pair")
    end
  end

  # --- Fixtures ---

  defp pair do
    %Pair{
      id: "thor1pair",
      address: "thor1pair",
      market_makers: [],
      token_base: "gaia-atom",
      token_quote: "eth-usdc-0xabc"
    }
  end

  defp vault do
    %Vault{
      id: "thor1vault",
      address: "thor1vault",
      denom: "rune",
      receipt_denom: "x/ghost-vault/rune"
    }
  end

  defp fin_info,
    do: %ContractInfo{address: "thor1pair", contract: "rujira-fin", version: "1"}

  defp mm_info,
    do: %ContractInfo{address: "thor1mm", contract: "legacy-mm", version: "1"}

  defp modern_mm_info,
    do: %ContractInfo{address: "thor1mm", contract: "modern-mm", version: "1"}

  defp failing_mm_info,
    do: %ContractInfo{address: "thor1mm", contract: "failing-mm", version: "1"}

  defp pair_config(market_makers \\ []) do
    %{
      "address" => "thor1pair",
      "market_makers" => market_makers,
      "denoms" => ["gaia-atom", "eth-usdc-0xabc"],
      "oracles" => [],
      "tick" => 6,
      "fee_taker" => "0.0015",
      "fee_maker" => "0.00075",
      "fee_address" => "thor1fee"
    }
  end
end
