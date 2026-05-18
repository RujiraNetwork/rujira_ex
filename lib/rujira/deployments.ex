defmodule Rujira.Deployments do
  @moduledoc """
  Resolves deployed Rujira contracts from THORChain's contract-info index.

  Queries `Thorchain.Types.Query.Stub.contract_infos/2` via the configured
  `Rujira.Node` implementation and maps each on-chain `ContractInfo` to a
  `Rujira.Deployments.Target`.

  ## Configuration

      config :rujira_ex,
        # Map of contract-name string -> module implementing the resource.
        # Rujira's own protocols (e.g. "rujira-fin") are mapped by default;
        # consumers add their own entries here.
        protocol_modules: %{"rujira-bow" => MyApp.Bow},

        # Addresses to exclude from the resolved target list (e.g. legacy
        # or unmaintained deployments).
        deployments_omit: []

  Consumers wire up cache invalidation themselves by calling
  `invalidate/0` whenever a `MsgInstantiateContract`, `MsgInstantiateContract2`
  or `MsgMigrateContract` is observed.
  """

  alias Rujira.Deployments.Target
  alias Thorchain.Types.ContractInfo
  alias Thorchain.Types.Query.Stub
  alias Thorchain.Types.QueryContractInfosRequest

  use Memoize

  @spec contract_infos() :: {:ok, [ContractInfo.t()]} | {:error, term()}
  defmemo contract_infos do
    with {:ok, %{infos: infos}} <-
           Rujira.Node.query(&Stub.contract_infos/2, %QueryContractInfosRequest{}) do
      {:ok, Enum.reject(infos, &(&1.address in omit()))}
    end
  end

  @spec get_target(module()) :: Target.t() | nil
  defmemo get_target(module) do
    case list_all_targets() do
      {:ok, targets} -> Enum.find(targets, &(&1.module === module))
      _ -> nil
    end
  end

  @spec from_address(String.t()) :: {:ok, Target.t()} | {:error, term()}
  defmemo from_address(address) do
    with {:ok, targets} <- list_all_targets() do
      case Enum.find(targets, &(&1.address == address)) do
        nil -> {:error, :not_found}
        target -> {:ok, target}
      end
    end
  end

  @spec list_all_targets() :: {:ok, [Target.t()]} | {:error, term()}
  defmemo list_all_targets do
    with {:ok, infos} <- contract_infos() do
      Rujira.Enum.reduce_while_ok(infos, [], &target/1)
    end
  end

  @doc "List all targets for a given module."
  @spec list_targets(module()) :: [Target.t()]
  defmemo list_targets(module) do
    case list_all_targets() do
      {:ok, targets} -> Enum.filter(targets, &(&1.module === module))
      _ -> []
    end
  end

  @doc "Invalidate all memoized deployment metadata."
  @spec invalidate() :: :ok
  def invalidate do
    Memoize.invalidate(__MODULE__, :contract_infos)
    Memoize.invalidate(__MODULE__, :get_target)
    Memoize.invalidate(__MODULE__, :from_address)
    Memoize.invalidate(__MODULE__, :list_all_targets)
    Memoize.invalidate(__MODULE__, :list_targets)
    :ok
  end

  # --- Private ---

  defp target(%{contract: name, version: version, address: address} = info) do
    case module_from(info) do
      {:ok, module} ->
        {:ok,
         %Target{
           id: address,
           address: address,
           module: module,
           name: name,
           version: version
         }}

      _ ->
        :skip
    end
  end

  defp module_from(%{contract: "rujira-fin"}), do: {:ok, Rujira.Fin.Pair}

  defp module_from(%{contract: name}) do
    case Map.get(protocol_modules(), name) do
      nil -> {:error, :unknown_protocol}
      module -> {:ok, module}
    end
  end

  defp protocol_modules, do: Application.get_env(:rujira_ex, :protocol_modules, %{})

  defp omit, do: Application.get_env(:rujira_ex, :deployments_omit, [])
end
