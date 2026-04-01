defmodule Rujira.Deployments do
  @moduledoc """
  Loads deployment configuration from YAML files and resolves contract targets.
  """

  alias Cosmwasm.Wasm.V1.ContractInfo
  alias Cosmwasm.Wasm.V1.MsgInstantiateContract2
  alias Cosmwasm.Wasm.V1.MsgMigrateContract
  alias Cosmwasm.Wasm.V1.MsgUpdateAdmin
  alias Rujira.Contracts
  alias Rujira.Deployments.Target

  use Memoize

  @path "data/deployments"

  @spec get_target(module(), term()) :: {:ok, Target.t()} | {:error, term()}
  defmemo get_target(module, id) do
    with {:ok, targets} <- list_all_targets() do
      case Enum.find(targets, &(&1.module === module and &1.id == id)) do
        nil -> {:error, :not_found}
        target -> {:ok, target}
      end
    end
  end

  @doc "Returns the address of a contract if it exists and is live"
  @spec get_address(module(), term()) :: {:ok, String.t()} | {:error, :not_found}
  defmemo get_address(module, id) do
    case get_target(module, id) do
      {:ok, %{address: address, status: :live}} -> {:ok, address}
      _ -> {:error, :not_found}
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
  defmemo list_all_targets() do
    %{codes: codes, targets: targets} = load_config!()

    with {:ok, result} <-
           Rujira.Enum.reduce_async_while_ok(
             targets,
             &parse_protocol(codes, &1),
             timeout: 30_000
           ) do
      {:ok, List.flatten(result)}
    end
  end

  @doc "List all targets for a given module"
  @spec list_targets(module()) :: {:ok, [Target.t()]} | {:error, term()}
  defmemo list_targets(module) do
    with {:ok, targets} <- list_all_targets() do
      {:ok, Enum.filter(targets, &(&1.module === module))}
    end
  end

  @spec contract_file_path(String.t()) :: String.t()
  defmemo contract_file_path(name) do
    plan = Application.get_env(:rujira_core, __MODULE__)[:plan]

    :rujira_core
    |> :code.priv_dir()
    |> Path.join(@path)
    |> Path.join(plan)
    |> Path.join("contracts")
    |> Path.join("#{name}.yaml")
  end

  defmemo load_config!() do
    plan = Application.get_env(:rujira_core, __MODULE__)[:plan]

    deploy_dir =
      :rujira_core
      |> :code.priv_dir()
      |> Path.join(@path)
      |> Path.join(plan)

    yaml_files =
      deploy_dir
      |> Path.join("contracts")
      |> File.ls!()

    {codes, targets} =
      Enum.reduce(yaml_files, {%{}, %{}}, fn file, {codes_acc, targets_acc} ->
        key = String.replace_suffix(file, ".yaml", "")
        full_path = deploy_dir |> Path.join("contracts") |> Path.join(file)

        %{"code" => code_id, "targets" => targets_list} = YamlElixir.read_from_file!(full_path)
        {Map.put(codes_acc, key, code_id), Map.put(targets_acc, key, targets_list)}
      end)

    accounts =
      deploy_dir
      |> Path.join("accounts.yaml")
      |> YamlElixir.read_from_file!()
      |> Map.fetch!("accounts")

    %{accounts: parsed_accounts} = parse_ctx(%{accounts: accounts}, %{})

    parse_ctx(
      %{accounts: parsed_accounts, codes: codes, targets: targets},
      %{accounts: parsed_accounts, codes: codes, targets: targets}
    )
  end

  defp parse_protocol(codes, {protocol, configs}) do
    with {:ok, result} <-
           Rujira.Enum.reduce_async_while_ok(
             configs,
             &parse_contract(codes, protocol, &1),
             timeout: 30_000
           ) do
      result
    end
  end

  defp parse_contract(
         codes,
         protocol,
         %{
           "id" => id,
           "admin" => admin,
           "creator" => creator,
           "config" => config
         } = item
       ) do
    code_id = Map.get(codes, protocol)
    salt = build_address_salt(protocol, id)

    address = Map.get(item, "address", Contracts.build_address!(salt, creator, code_id))

    contract =
      case Contracts.info(address) do
        {:ok, info} -> info
        _ -> nil
      end

    %Target{
      id: id,
      address: address,
      creator: creator,
      code_id: code_id,
      salt: salt,
      admin: admin,
      protocol: protocol,
      module: to_module(protocol),
      config: config,
      contract: contract,
      status:
        case contract do
          nil -> :preview
          _ -> :live
        end
    }
  end

  # Existing contract, change, migrate
  def to_msg(%{
        address: address,
        module: module,
        code_id: target_code_id,
        config: config,
        contract: %ContractInfo{admin: admin, code_id: code_id}
      })
      when target_code_id != code_id do
    %MsgMigrateContract{
      sender: admin,
      code_id: Kernel.to_string(target_code_id),
      contract: address,
      msg: module.migrate_msg(code_id, target_code_id, config)
    }
  end

  def to_msg(%{address: address, admin: target_admin, contract: %ContractInfo{admin: admin}})
      when target_admin != admin,
      do: %MsgUpdateAdmin{sender: admin, new_admin: target_admin, contract: address}

  # No contract, instantiate
  def to_msg(%{
        id: id,
        module: module,
        code_id: code_id,
        config: config,
        salt: salt,
        admin: admin,
        creator: creator,
        contract: nil
      }) do
    %MsgInstantiateContract2{
      sender: creator,
      admin: admin,
      code_id: Kernel.to_string(code_id),
      msg: module.init_msg(config),
      funds: [],
      label: module.init_label(id, config),
      salt: Base.encode64(Base.decode16!(salt))
    }
  end

  # Existing contract, no change, ignore
  def to_msg(%{contract: %ContractInfo{}}), do: nil

  # Protocol -> module mapping
  def to_module("rujira-fin"), do: Rujira.Fin.Pair

  def to_module(protocol) do
    Map.get(Application.get_env(:rujira_core, :protocol_modules, %{}), protocol)
  end

  def parse_arg("targets:" <> id, %{targets: targets, codes: codes} = ctx) do
    [protocol, id] = String.split(id, ".")
    code_id = Map.get(codes, protocol)

    target =
      targets
      |> Map.get(protocol)
      |> Enum.find(&(Map.get(&1, "id") == id))

    creator = target |> Map.get("creator") |> interpolate_string(ctx)
    salt = build_address_salt(protocol, id)

    Map.get(target, "address", Contracts.build_address!(salt, creator, code_id))
  end

  def parse_arg("accounts:" <> id, %{accounts: accounts}), do: Map.get(accounts, id)
  def parse_arg("env:" <> id, _), do: System.get_env(id)
  def parse_arg(x, _), do: x

  def build_address_salt("rujira-" <> protocol, id), do: Base.encode16("#{protocol}:#{id}")
  def build_address_salt("nami-" <> protocol, id), do: Base.encode16("#{protocol}:#{id}")
  def build_address_salt(protocol, id), do: Base.encode16("#{protocol}:#{id}")

  def to_migrate_tx do
    %{codes: codes, targets: targets} = load_config!()

    messages =
      targets
      |> Enum.flat_map(&parse_protocol(codes, &1))
      |> Enum.map(fn x -> Map.put(x, :msg, to_msg(x)) end)
      |> Enum.reduce([], fn
        %{msg: nil}, a ->
          a

        %{msg: %struct{} = msg}, a ->
          name = struct |> Kernel.to_string() |> String.split(".") |> Enum.at(-1)

          [
            msg
            |> Map.from_struct()
            |> Map.delete(:__unknown_fields__)
            |> Map.delete(:fix_msg)
            |> Map.put("@type", "/cosmwasm.wasm.v1.#{name}")
            | a
          ]
      end)

    %{
      body: %{
        messages: messages,
        memo: "",
        timeout_height: "0",
        extension_options: [],
        non_critical_extension_options: []
      },
      auth_info: %{
        signer_infos: [],
        fee: %{amount: [], gas_limit: "1000000", payer: "", granter: ""},
        tip: nil
      },
      signatures: []
    }
    |> JSON.encode!()
  end

  # --- Private ---

  defp parse_ctx(map, ctx) when is_map(map) do
    map
    |> Enum.map(fn {k, v} -> {k, parse_ctx(v, ctx)} end)
    |> Enum.into(%{})
  end

  defp parse_ctx(v, ctx) when is_list(v), do: Enum.map(v, &parse_ctx(&1, ctx))
  defp parse_ctx(v, ctx) when is_binary(v), do: interpolate_string(v, ctx)
  defp parse_ctx(v, _), do: v

  defp interpolate_string(str, ctx) do
    case Regex.run(~r/^\${(.*)}$/, str) do
      nil -> str
      [_, x] -> parse_arg(x, ctx)
    end
  end
end
