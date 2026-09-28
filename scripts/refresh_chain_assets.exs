# Regenerates test/fixtures/chain_assets.json from a live THORChain node.
#
# The fixture is the offline snapshot test/rujira/assets/chain_assets_test.exs
# runs against: every bank denom, the denom metadata the chain holds for the
# token-factory ones, and every pool asset id. Nothing here runs in the test
# suite - this script is a maintenance tool, and `mix.exs` keeps `scripts/` out
# of the Hex package.
#
# Run it against a node, from the project root:
#
#     NODE_GRPC=grpc.thorchain.example:443 NODE_GRPC_TOKEN=<token> \
#       mix run scripts/refresh_chain_assets.exs
#
#   * NODE_GRPC       - host:port of the node's gRPC endpoint. A `:443` port
#                       connects over TLS, anything else in plaintext.
#   * NODE_GRPC_TOKEN - optional; sent as `authorization: Bearer <token>` on
#                       every request. Omit it for an unauthenticated node.
#
# This script pins `adapter: GRPC.Client.Adapters.Gun`. `:gun` is a dev-only
# dependency of this repo (see mix.exs) - run this script in the dev env
# (`mix run scripts/refresh_chain_assets.exs`, not `MIX_ENV=test`). A node impl
# configured by a consumer application is not used here - this script talks to
# the node itself, so a regenerated fixture never depends on the code it is
# testing.

defmodule RefreshChainAssets do
  @moduledoc false

  alias Cosmos.Bank.V1beta1.Query.Stub, as: BankStub
  alias Cosmos.Bank.V1beta1.QueryDenomMetadataRequest
  alias Cosmos.Bank.V1beta1.QueryTotalSupplyRequest
  alias Cosmos.Base.Query.V1beta1.PageRequest
  alias Thorchain.Types.Query.Stub, as: ThorchainStub
  alias Thorchain.Types.QueryPoolsRequest

  @fixture "test/fixtures/chain_assets.json"

  def run do
    Application.ensure_all_started(:gun)

    channel = connect(System.get_env("NODE_GRPC") || raise("NODE_GRPC is not set"))

    denoms = denoms(channel, nil)
    IO.puts("#{length(denoms)} denoms")

    metadata = metadata(channel, Enum.filter(denoms, &String.starts_with?(&1, "x/")))
    IO.puts("#{map_size(metadata)} denoms with metadata")

    pools = pools(channel)
    IO.puts("#{length(pools)} pools")

    File.write!(@fixture, render(Enum.sort(denoms), metadata, Enum.sort(pools)))
    IO.puts("wrote #{@fixture}")
  end

  # --- Node ---

  defp connect(endpoint) do
    opts = [adapter: GRPC.Client.Adapters.Gun, headers: headers()]

    opts =
      if String.ends_with?(endpoint, ":443"),
        do: Keyword.put(opts, :cred, GRPC.Credential.new(ssl: [verify: :verify_none])),
        else: opts

    case GRPC.Stub.connect(endpoint, opts) do
      {:ok, channel} -> channel
      {:error, reason} -> raise "cannot connect to #{endpoint}: #{inspect(reason)}"
    end
  end

  defp headers do
    case System.get_env("NODE_GRPC_TOKEN") do
      nil -> []
      "" -> []
      token -> [{"authorization", "Bearer #{token}"}]
    end
  end

  defp query(channel, fun, request) do
    fun.(channel, request, timeout: 60_000)
  end

  # --- Reads ---

  defp denoms(channel, key) do
    request =
      case key do
        nil -> %QueryTotalSupplyRequest{}
        key -> %QueryTotalSupplyRequest{pagination: %PageRequest{key: key}}
      end

    case query(channel, &BankStub.total_supply/3, request) do
      {:ok, %{supply: supply, pagination: %{next_key: ""}}} ->
        Enum.map(supply, & &1.denom)

      {:ok, %{supply: supply, pagination: %{next_key: next_key}}} ->
        Enum.map(supply, & &1.denom) ++ denoms(channel, next_key)

      {:error, error} ->
        raise "total supply: #{inspect(error)}"
    end
  end

  # A denom the node holds no metadata for is left out of the fixture - that is
  # the reply the test serves as "no metadata for this denom".
  defp metadata(channel, denoms) do
    denoms
    |> Enum.flat_map(fn denom ->
      case query(channel, &BankStub.denom_metadata/3, %QueryDenomMetadataRequest{denom: denom}) do
        {:ok, %{metadata: %{symbol: symbol} = metadata}} when symbol != "" ->
          [{denom, metadata}]

        {:ok, _} ->
          []

        {:error, %GRPC.RPCError{status: 5}} ->
          []

        {:error, error} ->
          raise "denom metadata #{denom}: #{inspect(error)}"
      end
    end)
    |> Map.new()
  end

  defp pools(channel) do
    case query(channel, &ThorchainStub.pools/3, %QueryPoolsRequest{}) do
      {:ok, %{pools: pools}} -> Enum.map(pools, & &1.asset)
      {:error, error} -> raise "pools: #{inspect(error)}"
    end
  end

  # --- Rendering ---

  # Written by hand rather than with an encoder: one denom, pool or metadata
  # entry per line keeps the diff of a refresh readable.
  defp render(denoms, metadata, pools) do
    """
    {
      "fetched_at": #{json(DateTime.to_iso8601(DateTime.utc_now()))},
      "denoms": [
    #{list(denoms)}
      ],
      "metadata": {
    #{entries(metadata)}
      },
      "pools": [
    #{list(pools)}
      ]
    }
    """
  end

  defp list(values), do: Enum.map_join(values, ",\n", &"    #{json(&1)}")

  defp entries(metadata) do
    metadata
    |> Enum.sort()
    |> Enum.map_join(",\n", fn {denom, m} ->
      units = Enum.map_join(m.denom_units, ", ", &json([&1.denom, &1.exponent]))

      """
          #{json(denom)}: {
            "symbol": #{json(m.symbol)},
            "display": #{json(m.display)},
            "name": #{json(m.name)},
            "denom_units": [#{units}]
          }\
      """
    end)
  end

  defp json(value), do: JSON.encode!(value)
end

RefreshChainAssets.run()
