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

  ## Query options

  `contract_infos/0,1` is cached per `Rujira.Cache`, against the contract
  registry, and resolved at `opts[:height]` or - without one - at the head.
  Every other lookup here derives from it in memory, so it costs no node read
  and is not cached on its own. The blocks a consumer feeds
  `Rujira.Node.advance/1` invalidate it; `Rujira.Cache.invalidate_all/0` is the
  fallback for a change no block announces.
  """

  alias Rujira.Cache
  alias Rujira.Deployments.Target
  alias Rujira.Node
  alias Thorchain.Types.ContractInfo
  alias Thorchain.Types.Query.Stub
  alias Thorchain.Types.QueryContractInfosRequest

  @default_protocol_modules %{
    "rujira-brune" => Rujira.Brune.Pool,
    "rujira-fin" => Rujira.Fin.Pair,
    "rujira-ghost-credit" => Rujira.Ghost.Credit,
    "rujira-ghost-vault" => Rujira.Ghost.Vault,
    "rujira-revenue" => Rujira.Revenue.Converter,
    "rujira-staking" => Rujira.Staking.Pool,
    "rujira-thorchain-swap" => Rujira.ThorchainSwap.Strategy
  }

  @spec contract_infos() :: {:ok, [ContractInfo.t()]} | {:error, term()}
  def contract_infos, do: contract_infos([])

  @doc "As `contract_infos/0`, read at `opts[:height]` when given."
  @spec contract_infos(Node.opts()) :: {:ok, [ContractInfo.t()]} | {:error, term()}
  def contract_infos(opts) do
    with {:ok, opts} <- Cache.pin(opts) do
      Cache.fetch({__MODULE__, :contract_infos, []}, [:contract_registry], opts, fn _height ->
        fetch_contract_infos(opts)
      end)
    end
  end

  @spec get_target(module()) :: {:ok, Target.t()} | {:error, :not_found | term()}
  def get_target(module), do: get_target(module, [])

  @doc "As `get_target/1`, resolved at `opts[:height]` when given."
  @spec get_target(module(), Node.opts()) :: {:ok, Target.t()} | {:error, :not_found | term()}
  def get_target(module, opts) do
    with {:ok, opts} <- Cache.pin(opts),
         {:ok, targets} <- list_all_targets(opts) do
      targets
      |> Enum.find(&(&1.module === module))
      |> ok_or_not_found()
    end
  end

  @spec from_address(String.t()) :: {:ok, Target.t()} | {:error, term()}
  def from_address(address), do: from_address(address, [])

  @doc "As `from_address/1`, resolved at `opts[:height]` when given."
  @spec from_address(String.t(), Node.opts()) :: {:ok, Target.t()} | {:error, term()}
  def from_address(address, opts) do
    with {:ok, opts} <- Cache.pin(opts),
         {:ok, targets} <- list_all_targets(opts) do
      targets
      |> Enum.find(&(&1.address == address))
      |> ok_or_not_found()
    end
  end

  @doc """
  Resolves a target by its `id`, which is always its contract `address` - see
  `target/1`. Round-trips: `from_id(x.id)` returns `x`.
  """
  @spec from_id(String.t()) :: {:ok, Target.t()} | {:error, term()}
  def from_id(id), do: from_address(id)

  @doc "As `from_id/1`, resolved at `opts[:height]` when given."
  @spec from_id(String.t(), Node.opts()) :: {:ok, Target.t()} | {:error, term()}
  def from_id(id, opts), do: from_address(id, opts)

  @spec list_all_targets() :: {:ok, [Target.t()]} | {:error, term()}
  def list_all_targets, do: list_all_targets([])

  @doc "As `list_all_targets/0`, resolved at `opts[:height]` when given."
  @spec list_all_targets(Node.opts()) :: {:ok, [Target.t()]} | {:error, term()}
  def list_all_targets(opts) do
    with {:ok, opts} <- Cache.pin(opts),
         {:ok, infos} <- contract_infos(opts) do
      Rujira.Enum.reduce_while_ok(infos, [], &target/1)
    end
  end

  @doc "List all targets for a given module."
  @spec list_targets(module()) :: {:ok, [Target.t()]} | {:error, term()}
  def list_targets(module), do: list_targets(module, [])

  @doc "As `list_targets/1`, resolved at `opts[:height]` when given."
  @spec list_targets(module(), Node.opts()) :: {:ok, [Target.t()]} | {:error, term()}
  def list_targets(module, opts) do
    with {:ok, opts} <- Cache.pin(opts),
         {:ok, targets} <- list_all_targets(opts) do
      {:ok, Enum.filter(targets, &(&1.module === module))}
    end
  end

  # --- Private ---

  defp fetch_contract_infos(opts) do
    with {:ok, %{infos: infos}} <-
           Node.query(&Stub.contract_infos/3, %QueryContractInfosRequest{}, opts) do
      {:ok, Enum.reject(infos, &(&1.address in omit()))}
    end
  end

  defp ok_or_not_found(nil), do: {:error, :not_found}
  defp ok_or_not_found(target), do: {:ok, target}

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
