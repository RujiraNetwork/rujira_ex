defmodule Rujira.Contracts do
  @moduledoc """
  Convenience methods for querying CosmWasm smart contracts.
  """
  alias Cosmos.Base.Query.V1beta1.PageRequest
  alias Cosmwasm.Wasm.V1.CodeInfoResponse
  alias Cosmwasm.Wasm.V1.ContractInfo
  alias Cosmwasm.Wasm.V1.Model
  alias Cosmwasm.Wasm.V1.Query.Stub
  alias Cosmwasm.Wasm.V1.QueryAllContractStateRequest
  alias Cosmwasm.Wasm.V1.QueryBuildAddressRequest
  alias Cosmwasm.Wasm.V1.QueryCodeRequest
  alias Cosmwasm.Wasm.V1.QueryCodeResponse
  alias Cosmwasm.Wasm.V1.QueryCodesRequest
  alias Cosmwasm.Wasm.V1.QueryContractInfoRequest
  alias Cosmwasm.Wasm.V1.QueryContractsByCodeRequest
  alias Cosmwasm.Wasm.V1.QueryRawContractStateRequest
  alias Cosmwasm.Wasm.V1.QuerySmartContractStateRequest
  alias Rujira.Deployments
  alias Rujira.Logger

  use Memoize

  defstruct [:id, :address, :info]

  @type t :: %__MODULE__{id: String.t(), address: String.t(), info: ContractInfo.t()}

  @spec from_id(String.t()) :: {:ok, t()}
  def from_id(id) do
    {:ok, %__MODULE__{id: id, address: id}}
  end

  @spec code_info(non_neg_integer()) ::
          {:ok, CodeInfoResponse.t()} | {:error, GRPC.RPCError.t()}
  defmemo code_info(code_id) do
    with {:ok, %{code_info: code_info}} <-
           Rujira.Node.query(&Stub.code/2, %QueryCodeRequest{code_id: code_id}) do
      {:ok, code_info}
    end
  end

  @spec version(String.t()) ::
          {:ok, %{contract: String.t(), version: String.t()} | nil} | {:error, term()}
  defmemo version(address) do
    case query_state_raw(address, :erlang.iolist_to_binary("contract_info")) do
      {:ok, %{"contract" => contract, "version" => version}} ->
        {:ok, %{contract: contract, version: version}}

      {:error, %{message: "codespace wasm code 22: no such contract:" <> _}} ->
        {:ok, nil}

      other ->
        other
    end
  end

  @spec build_address(binary(), String.t(), non_neg_integer() | String.t()) ::
          {:ok, String.t()} | {:error, term()}
  defmemo build_address(salt, creator, id) when is_integer(id) do
    with {:ok, %{data_hash: data_hash}} <- code_info(id) do
      build_address(salt, creator, Base.encode16(data_hash))
    end
  end

  defmemo build_address(salt, creator, hash) do
    with {:ok, %{address: address}} <-
           Rujira.Node.query(
             &Stub.build_address/2,
             %QueryBuildAddressRequest{
               code_hash: hash,
               creator_address: creator,
               salt: salt
             }
           ) do
      {:ok, address}
    end
  end

  @spec build_address!(binary(), String.t(), non_neg_integer() | String.t()) :: String.t()
  defmemo build_address!(salt, deployer, code_id) do
    {:ok, address} = build_address(salt, deployer, code_id)
    address
  end

  @spec info(String.t()) ::
          {:ok, ContractInfo.t()} | {:error, GRPC.RPCError.t()}
  defmemo info(address) do
    with {:ok, %{contract_info: contract_info}} <-
           Rujira.Node.query(
             &Stub.contract_info/2,
             %QueryContractInfoRequest{address: address}
           ) do
      {:ok, contract_info}
    end
  end

  @spec codes() :: {:ok, list(CodeInfoResponse.t())} | {:error, GRPC.RPCError.t()}
  defmemo codes() do
    codes_page()
  end

  defp codes_page(key \\ nil)

  defp codes_page(nil) do
    with {:ok, %{code_infos: code_infos, pagination: %{next_key: next_key}}} <-
           Rujira.Node.query(&Stub.codes/2, %QueryCodesRequest{}),
         {:ok, next} <- codes_page(next_key) do
      {:ok, Enum.concat(code_infos, next)}
    end
  end

  defp codes_page(""), do: {:ok, []}

  defp codes_page(key) do
    with {:ok, %{code_infos: code_infos, pagination: %{next_key: next_key}}} <-
           Rujira.Node.query(
             &Stub.codes/2,
             %QueryCodesRequest{pagination: %PageRequest{key: key}}
           ),
         {:ok, next} <- codes_page(next_key) do
      {:ok, Enum.concat(code_infos, next)}
    end
  end

  @spec by_code(integer()) ::
          {:ok, list(String.t())} | {:error, GRPC.RPCError.t()}
  defmemo by_code(code_id) do
    with {:ok, contracts} <- by_code_page(code_id) do
      {:ok, Enum.map(contracts, &%__MODULE__{id: &1, address: &1})}
    end
  end

  defp by_code_page(code_id, key \\ nil)

  defp by_code_page(code_id, nil) do
    with {:ok, %{contracts: contracts, pagination: %{next_key: next_key}}} <-
           Rujira.Node.query(
             &Stub.contracts_by_code/2,
             %QueryContractsByCodeRequest{code_id: code_id}
           ),
         {:ok, next} <- by_code_page(code_id, next_key) do
      {:ok, Enum.concat(contracts, next)}
    end
  end

  defp by_code_page(_code_id, ""), do: {:ok, []}

  defp by_code_page(code_id, key) do
    with {:ok, %{contracts: contracts, pagination: %{next_key: next_key}}} <-
           Rujira.Node.query(
             &Stub.contracts_by_code/2,
             %QueryContractsByCodeRequest{
               code_id: code_id,
               pagination: %PageRequest{key: key}
             }
           ),
         {:ok, next} <- by_code_page(code_id, next_key) do
      {:ok, Enum.concat(contracts, next)}
    end
  end

  @spec code(integer()) :: {:ok, QueryCodeResponse} | {:error, GRPC.RPCError.t()}
  defmemo code(id) do
    with {:ok, %{code_info: code_info}} <-
           Rujira.Node.query(&Stub.code/2, %QueryCodeRequest{code_id: id}) do
      {:ok, code_info}
    end
  end

  @spec by_codes(list(integer())) ::
          {:ok, list(String.t())} | {:error, GRPC.RPCError.t()}
  def by_codes(code_ids) do
    Enum.reduce(code_ids, {:ok, []}, fn
      el, {:ok, agg} ->
        case by_code(el) do
          {:ok, contracts} -> {:ok, agg ++ contracts}
          err -> err
        end

      _, err ->
        err
    end)
  end

  @spec get({module(), String.t() | __MODULE__.t()} | struct()) ::
          {:ok, struct()} | {:error, any()}

  defmemo(get({module, %__MODULE__{address: address}}), do: get({module, address}))

  defmemo get({module, address}) do
    case query_state_smart(address, %{config: %{}}) do
      {:ok, config} ->
        config |> Map.put("address", address) |> module.new()

      {:error,
       %GRPC.RPCError{
         status: 2,
         message: "codespace wasm code 22: no such contract: address " <> _
       }} ->
        from_target({module, address})

      err ->
        err
    end
  end

  @spec from_target({module(), String.t()}) :: {:ok, struct()} | {:error, term()}
  def from_target({module, address}) do
    case Deployments.list_all_targets() do
      {:ok, targets} ->
        case Enum.find(targets, &(&1.address == address)) do
          nil -> {:error, :not_found}
          x -> module.new(x)
        end

      error ->
        error
    end
  end

  defmemo(get(_channel, loaded), do: {:ok, loaded})

  @spec list(module(), list(integer())) ::
          {:ok, list(struct())} | {:error, GRPC.RPCError.t()}
  defmemo list(module, code_ids) when is_list(code_ids) do
    with {:ok, contracts} <- by_codes(code_ids),
         {:ok, struct} <-
           contracts
           |> Rujira.Enum.reduce_async_while_ok(&get({module, &1}), timeout: 30_000) do
      {:ok, struct}
    end
  end

  @spec query_state_raw(String.t(), binary()) ::
          {:ok, term()} | {:error, :not_found} | {:error, GRPC.RPCError.t()}
  def query_state_raw(address, query) do
    case Rujira.Node.query(
           &Stub.raw_contract_state/2,
           %QueryRawContractStateRequest{
             address: address,
             query_data: query
           }
         ) do
      {:ok, %{data: ""}} -> {:error, :not_found}
      {:ok, %{data: data}} -> JSON.decode(data)
      other -> other
    end
  end

  @spec query_state_smart(String.t(), map()) ::
          {:ok, map()} | {:error, GRPC.RPCError.t()}
  def query_state_smart(address, query) do
    with {:ok, %{data: data}} <-
           Rujira.Node.query(&Stub.smart_contract_state/2, %QuerySmartContractStateRequest{
             address: address,
             query_data: JSON.encode!(query)
           }) do
      JSON.decode(data)
    end
  end

  @spec query_state_smart(String.t(), map(), keyword()) ::
          {:ok, map()} | {:error, GRPC.RPCError.t()}
  def query_state_smart(address, query, opts) do
    with {:ok, %{data: data}} <-
           Rujira.Node.query(
             &Stub.smart_contract_state/3,
             %QuerySmartContractStateRequest{
               address: address,
               query_data: JSON.encode!(query)
             },
             opts
           ) do
      JSON.decode(data)
    end
  end

  @doc """
  Paginates through a smart contract query result set.
  """
  @spec paginate(
          {:ok, map()} | {:error, any()},
          String.t(),
          pos_integer(),
          (list() -> {:ok, list()} | {:error, any()})
        ) :: {:ok, list()} | {:error, any()}
  def paginate(result, key, limit, next_fn)

  def paginate({:ok, %{} = res}, key, limit, next_fn) do
    items = Map.get(res, key, [])

    if length(items) == limit do
      with {:ok, next} <- next_fn.(items), do: {:ok, items ++ next}
    else
      {:ok, items}
    end
  end

  def paginate(err, _, _, _), do: err

  @doc "Queries the full, raw contract state at an address"
  @spec query_state_all(String.t()) ::
          {:ok, map()} | {:error, GRPC.RPCError.t()}
  defmemo query_state_all(address) do
    query_state_all_page(address, nil)
  end

  defp query_state_all_page(address, page) do
    with {:ok, %{models: models, pagination: %{next_key: next_key}}} when next_key != "" <-
           Rujira.Node.query(
             &Stub.all_contract_state/2,
             %QueryAllContractStateRequest{address: address, pagination: page}
           ),
         {:ok, next} <-
           query_state_all_page(address, %PageRequest{key: next_key}) do
      {:ok, decode_models(models, next)}
    else
      {:ok, %{models: models, pagination: %{next_key: nil}}} ->
        {:ok, decode_models(models)}

      {:ok, %{models: models, pagination: %{next_key: ""}}} ->
        {:ok, decode_models(models)}

      err ->
        err
    end
  end

  @doc "Streams the current contract state"
  @spec stream_state_all(String.t()) :: Enumerable.t()
  def stream_state_all(address) do
    Stream.resource(
      fn ->
        Rujira.Node.query(
          &Stub.all_contract_state/2,
          %QueryAllContractStateRequest{address: address}
        )
      end,
      fn
        {:ok,
         %{
           models: [%{value: value}],
           pagination: %{next_key: next_key}
         }}
        when next_key != "" ->
          next =
            Rujira.Node.query(
              &Stub.all_contract_state/2,
              %QueryAllContractStateRequest{
                address: address,
                pagination: %PageRequest{key: next_key}
              }
            )

          {[JSON.decode!(value)], next}

        {:ok, %{models: [%{value: value} | xs]} = agg} ->
          {[JSON.decode!(value)], {:ok, %{agg | models: xs}}}

        {:ok, %{models: [], pagination: %{next_key: ""}}} = acc ->
          {:halt, acc}
      end,
      fn _ -> nil end
    )
  end

  @spec query_state_smart_with_retry(String.t(), map()) ::
          {:ok, map()} | {:error, term()}
  def query_state_smart_with_retry(address, query) do
    case query_state_smart(address, query) |> log_retry(address, query) do
      {:error, %GRPC.RPCError{status: 2, message: msg}}
      when msg in [
             "Invalid layer 1 string : query wasm contract failed",
             "codespace wasm code 29: wasmvm error: Error calling the VM: Error executing Wasm: Wasmer runtime error: RuntimeError: Error calling into the VM's backend: Panic in FFI call",
             "Generic error: Parsing u128: cannot parse integer from empty string: query wasm contract failed",
             "failed to decode Protobuf message: invalid tag value: 0: query wasm contract failed",
             "Generic error: Parsing u128: invalid digit found in string: query wasm contract failed",
             "Generic error: Error parsing whole: query wasm contract failed"
           ] ->
        query_state_smart(address, query)

      other ->
        other
    end
  end

  # --- Private ---

  defp decode_models(models, init \\ %{}) do
    Enum.reduce(models, init, fn %Model{} = model, agg ->
      Map.put(agg, model.key, JSON.decode!(model.value))
    end)
  end

  defp log_retry({:error, %GRPC.RPCError{status: status, message: message}} = err, address, query) do
    Logger.error(__MODULE__, "GRPC Retry: #{address} #{inspect(query)} #{status} #{message}")
    err
  end

  defp log_retry(other, _, _), do: other
end
