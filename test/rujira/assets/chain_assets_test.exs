defmodule Rujira.Assets.ChainAssetsTest do
  @moduledoc """
  Every asset on THORChain mainnet, converted offline.

  `test/fixtures/chain_assets.json` is a snapshot of the chain: every bank
  denom, the denom metadata the node holds for the token-factory ones, and every
  pool asset id. One test per denom and per pool, so a failure names the asset
  that broke. Refresh it with `scripts/refresh_chain_assets.exs`.
  """

  # Not async: the metadata cache is global, and this reads the whole chain
  # through it.
  use Rujira.Test.CacheCase, async: false

  alias Cosmos.Bank.V1beta1.DenomUnit
  alias Cosmos.Bank.V1beta1.Metadata, as: DenomMetadata
  alias Cosmos.Bank.V1beta1.QueryDenomMetadataRequest
  alias Cosmos.Bank.V1beta1.QueryDenomMetadataResponse
  alias Rujira.Assets
  alias Rujira.Assets.Asset
  alias Rujira.Assets.Metadata
  alias Rujira.Test.MockNode

  @chain "test/fixtures/chain_assets.json" |> File.read!() |> JSON.decode!()
  @denoms @chain["denoms"]
  @metadata @chain["metadata"]
  @pools @chain["pools"]

  setup do
    serve_chain_metadata()
  end

  describe "every bank denom" do
    for denom <- @denoms do
      test denom do
        assert_denom(unquote(denom))
      end
    end
  end

  describe "every pool" do
    for pool <- @pools do
      test pool do
        assert_pool(unquote(pool))
      end
    end
  end

  describe "a denom the node holds no metadata for" do
    setup do
      serve_no_metadata()
    end

    test "names bRUNE itself" do
      assert {:ok, %Asset{id: "x/brune", symbol: "bRUNE", ticker: "bRUNE"}} =
               Assets.from_denom("x/brune")
    end

    test "names a staking receipt after its bond denom" do
      assert {:ok, %Asset{id: "x/staking-rune", symbol: "sRUNE", ticker: "sRUNE"}} =
               Assets.from_denom("x/staking-rune")

      assert {:ok, %Asset{id: "x/staking-tcy", ticker: "sTCY"}} =
               Assets.from_denom("x/staking-tcy")
    end

    test "names a staking receipt whose bond denom is not a denom after itself" do
      assert {:ok, %Asset{id: "x/staking-uruji", ticker: "staking-uruji"}} =
               Assets.from_denom("x/staking-uruji")
    end

    test "names anything else after the denom, as the chain spells it" do
      assert {:ok, %Asset{id: "x/Foo-Bar", symbol: "Foo-Bar", ticker: "Foo-Bar"}} =
               Assets.from_denom("x/Foo-Bar")
    end

    test "records the derived name as the asset's metadata, with no decimals" do
      assert {:ok, %Asset{metadata: %Metadata{symbol: "bRUNE", decimals: nil}} = asset} =
               Assets.from_denom("x/brune")

      assert Assets.decimals(asset) == 8
    end

    test "resolves from_id/1 the same way" do
      assert {:ok, %Asset{ticker: "bRUNE"}} = Assets.from_id("x/brune")
    end
  end

  describe "a metadata read that fails for any other reason" do
    test "returns the node's error unchanged from from_denom/1" do
      serve_metadata_error(%GRPC.RPCError{status: 13, message: "boom"})

      assert {:error, %GRPC.RPCError{status: 13, message: "boom"}} =
               Assets.from_denom("x/ruji-error-test")
    end

    test "returns the node's error unchanged from from_id/1" do
      serve_metadata_error(%GRPC.RPCError{status: 13, message: "boom"})

      assert {:error, %GRPC.RPCError{status: 13}} = Assets.from_id("x/ruji-error-test")
    end

    test "does not read a not-found status as a denom with no metadata" do
      serve_metadata_error(%GRPC.RPCError{status: 5, message: "unknown request"})

      assert {:error, %GRPC.RPCError{status: 5, message: "unknown request"}} =
               Assets.from_denom("x/brune-error-test")
    end

    test "propagates the error the bond denom of a staking receipt fails with" do
      serve_metadata_error(%GRPC.RPCError{status: 13, message: "boom"})

      assert {:error, %GRPC.RPCError{status: 13}} =
               Assets.from_denom("x/staking-x/bond-error-test")
    end
  end

  # --- Assertions ---

  defp assert_denom(denom) do
    assert {:ok, %Asset{} = asset} = Assets.from_denom(denom)
    assert asset.type == denom_type(denom)

    # One id, one asset: an id read back resolves to the asset it came from.
    assert {:ok, ^asset} = Assets.from_id(asset.id)

    assert_native(denom, asset)
    assert_identity(denom, asset)
    assert_forms(asset)
  end

  defp assert_native(_denom, %Asset{type: type} = asset) when type in [:synth, :trade],
    do: assert({:error, :no_native_denom} = Assets.to_native(asset))

  defp assert_native(denom, asset), do: assert({:ok, ^denom} = Assets.to_native(asset))

  # A token-factory denom is whatever the chain's metadata says it is.
  defp assert_identity("x/" <> _ = denom, %Asset{} = asset) do
    metadata = Map.fetch!(@metadata, denom)

    assert asset.ticker == metadata["symbol"]
    assert Assets.decimals(asset) == metadata_decimals(metadata)
  end

  defp assert_identity(_denom, _asset), do: :ok

  defp assert_forms(%Asset{type: :secured} = asset) do
    assert {:ok, %Asset{type: :layer_1} = layer_1} = Assets.to_layer1(asset)
    assert {:ok, ^asset} = Assets.to_secured(layer_1)
  end

  defp assert_forms(%Asset{type: type} = asset) when type in [:synth, :trade],
    do: assert({:ok, %Asset{type: :layer_1}} = Assets.to_layer1(asset))

  defp assert_forms(_asset), do: :ok

  defp assert_pool("THOR." <> _ = id) do
    assert {:ok, %Asset{id: ^id, type: :native}} = Assets.from_id(id)
  end

  defp assert_pool(id) do
    assert {:ok, %Asset{id: ^id, type: :layer_1} = asset} = Assets.from_id(id)

    # The pool's asset, credited on THORChain: secured, its bank denom, and back.
    assert {:ok, %Asset{type: :secured} = secured} = Assets.to_secured(asset)
    assert {:ok, denom} = Assets.to_native(secured)
    assert {:ok, ^secured} = Assets.from_denom(denom)
    assert {:ok, ^asset} = Assets.to_layer1(secured)
  end

  # --- The chain, offline ---

  defp denom_type("rune"), do: :native
  defp denom_type("tcy"), do: :native
  defp denom_type("tor"), do: :native
  defp denom_type("thor." <> _), do: :native
  defp denom_type("x/" <> _), do: :native

  defp denom_type(denom) do
    cond do
      String.contains?(denom, "/") -> :synth
      String.contains?(denom, "~") -> :trade
      String.contains?(denom, "-") -> :secured
    end
  end

  # The decimals the chain declares: the exponent of its display unit, or the
  # largest exponent when the display unit is the base unit.
  defp metadata_decimals(%{"display" => display, "denom_units" => denom_units}) do
    case Enum.find(denom_units, fn [denom, _] -> denom == display end) do
      [_, exponent] when exponent > 0 -> exponent
      _ -> denom_units |> Enum.map(fn [_, exponent] -> exponent end) |> Enum.max()
    end
  end

  defp serve_chain_metadata do
    MockNode.expect(fn %QueryDenomMetadataRequest{denom: denom} ->
      metadata_reply(Map.get(@metadata, denom), denom)
    end)
  end

  defp serve_no_metadata do
    MockNode.expect(fn %QueryDenomMetadataRequest{denom: denom} -> metadata_reply(nil, denom) end)
  end

  defp serve_metadata_error(error) do
    MockNode.expect(fn %QueryDenomMetadataRequest{} -> {:error, error} end)
  end

  # The node's own reply for a denom it holds no metadata for.
  defp metadata_reply(nil, denom),
    do: {:error, %GRPC.RPCError{status: 5, message: "client metadata for denom #{denom}"}}

  defp metadata_reply(metadata, _denom) do
    {:ok,
     %QueryDenomMetadataResponse{
       metadata: %DenomMetadata{
         description: "",
         display: metadata["display"],
         name: metadata["name"],
         symbol: metadata["symbol"],
         uri: "",
         uri_hash: "",
         denom_units:
           Enum.map(metadata["denom_units"], fn [denom, exponent] ->
             %DenomUnit{denom: denom, exponent: exponent}
           end)
       }
     }}
  end
end
