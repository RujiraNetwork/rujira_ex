defmodule Rujira.Deployments do
  @moduledoc """
  Resolves deployed Rujira contracts from THORChain's contract-info index.

  Queries `Thorchain.Types.Query.Stub.contract_infos/3` via the configured
  `Rujira.Node` implementation and maps each on-chain `ContractInfo` to a
  `Rujira.Deployments.Target`.

  ## Configuration

      config :rujira_ex,
        # Map of contract-name string -> module implementing the resource.
        # Rujira's own protocols (e.g. "rujira-fin", "rujira-ghost-vault",
        # "rujira-thorchain-swap") are mapped by default; a consumer entry for
        # the same contract name takes precedence over the built-in default,
        # so consumers can override or extend the mapping.
        protocol_modules: %{"rujira-merge" => MyApp.Merge},

        # Addresses to exclude from the resolved target list (e.g. legacy
        # or unmaintained deployments).
        deployments_omit: []

  Consumers wire up cache invalidation themselves by calling
  `invalidate/0` whenever a `MsgInstantiateContract`, `MsgInstantiateContract2`
  or `MsgMigrateContract` is observed.

  ## Query options

  Every lookup keeps its memoized arity and gains a sibling one arity higher
  that takes `opts`: with a `:height` it resolves the whole chain of lookups
  uncached at that height - a height read is never cached - and without one it
  is the memoized function itself, so the other opts are not applied.
  """

  alias Rujira.Deployments.Target
  alias Rujira.Node
  alias Thorchain.Types.ContractInfo
  alias Thorchain.Types.Query.Stub
  alias Thorchain.Types.QueryContractInfosRequest

  use Memoize

  @default_protocol_modules %{
    "rujira-brune" => Rujira.Brune.Pool,
    "rujira-fin" => Rujira.Fin.Pair,
    "rujira-ghost-vault" => Rujira.Ghost.Vault,
    "rujira-staking" => Rujira.Staking.Pool,
    "rujira-thorchain-swap" => Rujira.ThorchainSwap.Strategy
  }

  @spec contract_infos() :: {:ok, [ContractInfo.t()]} | {:error, term()}
  defmemo(contract_infos, do: fetch_contract_infos([]))

  @doc "As `contract_infos/0`, read at `opts[:height]` when given."
  @spec contract_infos(Node.opts()) :: {:ok, [ContractInfo.t()]} | {:error, term()}
  def contract_infos(opts) do
    Node.at_height(opts, fn -> fetch_contract_infos(opts) end, &contract_infos/0)
  end

  @spec get_target(module()) :: {:ok, Target.t()} | {:error, :not_found | term()}
  defmemo(get_target(module), do: fetch_get_target_result(module, []))

  @doc "As `get_target/1`, resolved at `opts[:height]` when given."
  @spec get_target(module(), Node.opts()) :: {:ok, Target.t()} | {:error, :not_found | term()}
  def get_target(module, opts) do
    Node.at_height(
      opts,
      fn -> fetch_get_target_result(module, opts) end,
      fn -> get_target(module) end
    )
  end

  @spec from_address(String.t()) :: {:ok, Target.t()} | {:error, term()}
  defmemo(from_address(address), do: fetch_from_address(address, []))

  @doc "As `from_address/1`, resolved at `opts[:height]` when given."
  @spec from_address(String.t(), Node.opts()) :: {:ok, Target.t()} | {:error, term()}
  def from_address(address, opts) do
    Node.at_height(
      opts,
      fn -> fetch_from_address(address, opts) end,
      fn -> from_address(address) end
    )
  end

  @spec list_all_targets() :: {:ok, [Target.t()]} | {:error, term()}
  defmemo(list_all_targets, do: fetch_list_all_targets([]))

  @doc "As `list_all_targets/0`, resolved at `opts[:height]` when given."
  @spec list_all_targets(Node.opts()) :: {:ok, [Target.t()]} | {:error, term()}
  def list_all_targets(opts) do
    Node.at_height(opts, fn -> fetch_list_all_targets(opts) end, &list_all_targets/0)
  end

  @doc "List all targets for a given module."
  @spec list_targets(module()) :: {:ok, [Target.t()]} | {:error, term()}
  defmemo(list_targets(module), do: fetch_list_targets_result(module, []))

  @doc "As `list_targets/1`, resolved at `opts[:height]` when given."
  @spec list_targets(module(), Node.opts()) :: {:ok, [Target.t()]} | {:error, term()}
  def list_targets(module, opts) do
    Node.at_height(
      opts,
      fn -> fetch_list_targets_result(module, opts) end,
      fn -> list_targets(module) end
    )
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

  defp fetch_contract_infos(opts) do
    with {:ok, %{infos: infos}} <-
           Node.query(&Stub.contract_infos/3, %QueryContractInfosRequest{}, opts) do
      {:ok, Enum.reject(infos, &(&1.address in omit()))}
    end
  end

  defp fetch_get_target_result(module, opts) do
    with {:ok, targets} <- list_all_targets(opts) do
      targets
      |> Enum.find(&(&1.module === module))
      |> ok_or_not_found()
    end
  end

  defp ok_or_not_found(nil), do: {:error, :not_found}
  defp ok_or_not_found(target), do: {:ok, target}

  defp fetch_from_address(address, opts) do
    with {:ok, targets} <- list_all_targets(opts) do
      case Enum.find(targets, &(&1.address == address)) do
        nil -> {:error, :not_found}
        target -> {:ok, target}
      end
    end
  end

  defp fetch_list_all_targets(opts) do
    with {:ok, infos} <- contract_infos(opts) do
      Rujira.Enum.reduce_while_ok(infos, [], &target/1)
    end
  end

  defp fetch_list_targets_result(module, opts) do
    with {:ok, targets} <- list_all_targets(opts) do
      {:ok, Enum.filter(targets, &(&1.module === module))}
    end
  end

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

  defp module_from(%{contract: name}) do
    case Map.get(protocol_modules(), name) do
      nil -> {:error, :unknown_protocol}
      module -> {:ok, module}
    end
  end

  defp protocol_modules,
    do:
      Map.merge(
        @default_protocol_modules,
        Application.get_env(:rujira_ex, :protocol_modules, %{})
      )

  defp omit, do: Application.get_env(:rujira_ex, :deployments_omit, [])
end
