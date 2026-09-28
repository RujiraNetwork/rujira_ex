defmodule Rujira.HeightErrorsTest do
  @moduledoc """
  A read at a height either answers with the state at that height or says it
  could not. Every function here used to answer a failed height read with a
  default - an empty book, a zero account, a skipped pair - and now hands the
  height error back instead.

  The FIN reads swallowed no error at all as of 0.6.0, so their blocks assert
  the error is handed back whatever it was; the rest still keep their default
  for an error that is not about the height.
  """
  use ExUnit.Case, async: false

  alias Rujira.Assets
  alias Rujira.Deployments
  alias Rujira.Fin
  alias Rujira.Fin.Pair
  alias Rujira.Ghost
  alias Rujira.Ghost.Vault
  alias Rujira.Test.MockNode
  alias Thorchain.Types.ContractInfo
  alias Thorchain.Types.QueryContractInfosRequest

  @height 500
  @unavailable %GRPC.RPCError{
    status: 2,
    message: "failed to load state at height 500: query wasm contract failed"
  }
  @other %GRPC.RPCError{status: 2, message: "boom: query wasm contract failed"}

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

    test "hands back any other error too, rather than an empty book" do
      MockNode.expect(fn %{"book" => _} -> {:error, @other} end)

      assert {:error, @other} = Fin.load_pair(pair())
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

    test "fails the whole list for any other error too, rather than skipping the pair" do
      MockNode.expect(fn
        %QueryContractInfosRequest{} -> {:ok, %{infos: [fin_info()]}}
        %{"config" => _} -> {:error, @other}
      end)

      assert {:error, @other} = Fin.list_pairs()
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

    test "hands back any other error from the list unchanged, not as an invalid id" do
      MockNode.expect(fn
        %QueryContractInfosRequest{} -> {:ok, %{infos: [fin_info()]}}
        %{"config" => _} -> {:error, @other}
      end)

      assert {:error, @other} = Fin.pair_from_id("atom/usdc")
    end

    test "still calls a malformed id invalid, and a pair that is not listed not found" do
      MockNode.expect(fn
        %QueryContractInfosRequest{} -> {:ok, %{infos: [fin_info()]}}
        %{"config" => _} -> MockNode.ok(pair_config())
      end)

      assert {:error, :invalid_id} = Fin.pair_from_id("atom/usdc/extra")
      assert {:error, :not_found} = Fin.pair_from_id("atom/usdc")
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
      MockNode.expect(fn _request -> {:error, @unavailable} end)

      assert {:error, {:height_unavailable, @height}} =
               Ghost.load_vault_account(vault(), "thor1acc", height: @height)
    end

    test "hands back any other error too - a zero account is no longer answered" do
      MockNode.expect(fn _request -> {:error, @other} end)

      assert {:error, @other} = Ghost.load_vault_account(vault(), "thor1acc")
    end
  end

  # --- Fixtures ---

  defp pair do
    {:ok, asset_base} = Assets.from_denom("gaia-atom")
    {:ok, asset_quote} = Assets.from_denom("eth-usdc-0xabc")

    %Pair{
      id: "thor1pair",
      address: "thor1pair",
      market_makers: [],
      asset_base: asset_base,
      asset_quote: asset_quote
    }
  end

  defp vault do
    {:ok, asset} = Assets.from_denom("rune")
    # `from_string/1` rather than `from_denom/1`: a receipt denom's asset is
    # named by the chain's metadata for it, and this fixture needs the denom,
    # not a node read.
    receipt_asset = Assets.from_string("x/ghost-vault/rune")

    %Vault{
      id: "thor1vault",
      address: "thor1vault",
      asset: asset,
      receipt_asset: receipt_asset
    }
  end

  defp fin_info,
    do: %ContractInfo{address: "thor1pair", contract: "rujira-fin", version: "1"}

  defp pair_config do
    %{
      "address" => "thor1pair",
      "market_makers" => [],
      "denoms" => ["gaia-atom", "eth-usdc-0xabc"],
      "oracles" => [],
      "tick" => 6,
      "fee_taker" => "0.0015",
      "fee_maker" => "0.00075",
      "fee_address" => "thor1fee"
    }
  end
end
