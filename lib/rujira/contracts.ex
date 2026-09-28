defmodule Rujira.Contracts do
  @moduledoc """
  Convenience methods for querying CosmWasm smart contracts.

  ## Query options

  Every query takes a trailing `opts`, forwarded to `Rujira.Node.query/3`, so a
  caller can read a whole composite at one `height:`.

  A memoized query keeps its name, arity and cache key, and gains a sibling one
  arity higher that takes `opts`: with a `:height` that sibling reads the node
  uncached - a height read is never cached - and without one it is the memoized
  function itself, so the other opts are not applied.
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
  alias Rujira.Logger
  alias Rujira.Node

  use Memoize

  # The node's suffix on every contract error raised while answering a wasm query.
  @wasm_query_failed ": query wasm contract failed"

  defstruct id: nil, address: nil, info: nil

  @type t :: %__MODULE__{id: String.t(), address: String.t(), info: ContractInfo.t() | nil}

  @spec from_id(String.t()) :: {:ok, t()}
  def from_id(id) do
    {:ok, %__MODULE__{id: id, address: id}}
  end

  @spec code_info(non_neg_integer()) ::
          {:ok, CodeInfoResponse.t()} | {:error, Node.rpc_error()}
  defmemo(code_info(code_id), do: fetch_code_info(code_id, []))

  @doc "As `code_info/1`, read at `opts[:height]` when given."
  @spec code_info(non_neg_integer(), Node.opts()) ::
          {:ok, CodeInfoResponse.t()} | {:error, Node.rpc_error()}
  def code_info(code_id, opts) do
    Node.at_height(opts, fn -> fetch_code_info(code_id, opts) end, fn -> code_info(code_id) end)
  end

  @doc """
  Reads the `contract_info` entry a `cw2`-instrumented contract writes at
  instantiation.

  An address that holds no contract - the node answers `codespace wasm code 22:
  no such contract` - is `{:error, :not_found}`, as is a contract that never
  wrote the entry, which the node answers with empty raw state.
  """
  @spec version(String.t()) ::
          {:ok, %{contract: String.t(), version: String.t()}}
          | {:error, :not_found}
          | {:error, term()}
  defmemo(version(address), do: fetch_version(address, []))

  @doc "As `version/1`, read at `opts[:height]` when given."
  @spec version(String.t(), Node.opts()) ::
          {:ok, %{contract: String.t(), version: String.t()}}
          | {:error, :not_found}
          | {:error, term()}
  def version(address, opts) do
    Node.at_height(opts, fn -> fetch_version(address, opts) end, fn -> version(address) end)
  end

  @spec build_address(binary(), String.t(), non_neg_integer() | String.t()) ::
          {:ok, String.t()} | {:error, term()}
  defmemo build_address(salt, creator, id) when is_integer(id) do
    with {:ok, %{data_hash: data_hash}} <- code_info(id) do
      build_address(salt, creator, Base.encode16(data_hash))
    end
  end

  defmemo build_address(salt, creator, hash) do
    fetch_build_address(salt, creator, hash, [])
  end

  @doc "As `build_address/3`, read at `opts[:height]` when given."
  @spec build_address(binary(), String.t(), non_neg_integer() | String.t(), Node.opts()) ::
          {:ok, String.t()} | {:error, term()}
  def build_address(salt, creator, id, opts) do
    Node.at_height(
      opts,
      fn -> fetch_build_address(salt, creator, id, opts) end,
      fn -> build_address(salt, creator, id) end
    )
  end

  @spec build_address!(binary(), String.t(), non_neg_integer() | String.t()) :: String.t()
  defmemo build_address!(salt, deployer, code_id) do
    {:ok, address} = build_address(salt, deployer, code_id)
    address
  end

  @doc "As `build_address!/3`, read at `opts[:height]` when given."
  @spec build_address!(binary(), String.t(), non_neg_integer() | String.t(), Node.opts()) ::
          String.t()
  def build_address!(salt, deployer, code_id, opts) do
    Node.at_height(
      opts,
      fn -> fetch_build_address!(salt, deployer, code_id, opts) end,
      fn -> build_address!(salt, deployer, code_id) end
    )
  end

  @spec info(String.t()) ::
          {:ok, ContractInfo.t()} | {:error, Node.rpc_error()}
  defmemo(info(address), do: fetch_info(address, []))

  @doc "As `info/1`, read at `opts[:height]` when given."
  @spec info(String.t(), Node.opts()) :: {:ok, ContractInfo.t()} | {:error, Node.rpc_error()}
  def info(address, opts) do
    Node.at_height(opts, fn -> fetch_info(address, opts) end, fn -> info(address) end)
  end

  @spec codes() :: {:ok, list(CodeInfoResponse.t())} | {:error, Node.rpc_error()}
  defmemo(codes(), do: codes_page(nil, []))

  @doc "As `codes/0`, read at `opts[:height]` when given."
  @spec codes(Node.opts()) :: {:ok, list(CodeInfoResponse.t())} | {:error, Node.rpc_error()}
  def codes(opts) do
    Node.at_height(opts, fn -> codes_page(nil, opts) end, &codes/0)
  end

  @spec by_code(integer()) ::
          {:ok, list(t())} | {:error, Node.rpc_error()}
  defmemo(by_code(code_id), do: fetch_by_code(code_id, []))

  @doc "As `by_code/1`, read at `opts[:height]` when given."
  @spec by_code(integer(), Node.opts()) :: {:ok, list(t())} | {:error, Node.rpc_error()}
  def by_code(code_id, opts) do
    Node.at_height(opts, fn -> fetch_by_code(code_id, opts) end, fn -> by_code(code_id) end)
  end

  @spec code(integer()) :: {:ok, QueryCodeResponse} | {:error, Node.rpc_error()}
  defmemo(code(id), do: fetch_code_info(id, []))

  @doc "As `code/1`, read at `opts[:height]` when given."
  @spec code(integer(), Node.opts()) :: {:ok, QueryCodeResponse} | {:error, Node.rpc_error()}
  def code(id, opts) do
    Node.at_height(opts, fn -> fetch_code_info(id, opts) end, fn -> code(id) end)
  end

  @spec by_codes(list(integer()), Node.opts()) ::
          {:ok, list(t())} | {:error, Node.rpc_error()}
  def by_codes(code_ids, opts \\ []) do
    Enum.reduce(code_ids, {:ok, []}, fn
      el, {:ok, agg} ->
        case by_code(el, opts) do
          {:ok, contracts} -> {:ok, agg ++ contracts}
          err -> err
        end

      _, err ->
        err
    end)
  end

  @doc """
  Loads `module`'s config from the contract at `address` and constructs it.

  An `address` that holds no contract, or a contract the node otherwise
  reports as missing, is `{:error, :not_found}`.
  """
  @spec get({module(), String.t() | __MODULE__.t()} | struct()) ::
          {:ok, struct()} | {:error, :not_found} | {:error, any()}

  defmemo(get({module, %__MODULE__{address: address}}), do: get({module, address}))

  defmemo get({module, address}) do
    fetch_get(module, address, [])
  end

  @doc "As `get/1`, read at `opts[:height]` when given."
  @spec get({module(), String.t() | t()} | struct(), Node.opts()) ::
          {:ok, struct()} | {:error, :not_found} | {:error, any()}
  def get({module, %__MODULE__{address: address}}, opts), do: get({module, address}, opts)

  def get({module, address}, opts) do
    Node.at_height(
      opts,
      fn -> fetch_get(module, address, opts) end,
      fn -> get({module, address}) end
    )
  end

  # TODO: remove the `from_config/2` fallback once rujira-api has migrated every
  # protocol module to expose `new/1`. Tracks the incremental adoption of
  # rujira_ex by rujira-api — see CONTRIBUTING.md.
  defp construct(module, address, config) do
    Code.ensure_loaded(module)

    cond do
      function_exported?(module, :new, 1) ->
        config |> Map.put("address", address) |> module.new()

      function_exported?(module, :from_config, 2) ->
        module.from_config(address, config)

      true ->
        {:error, {:no_constructor, module}}
    end
  end

  @spec list(module(), list(integer())) ::
          {:ok, list(struct())} | {:error, Node.rpc_error()}
  defmemo list(module, code_ids) when is_list(code_ids) do
    fetch_list(module, code_ids, [])
  end

  @doc """
  As `list/2`, read at `opts[:height]` when given.

  Each contract is read concurrently; `opts[:fan_out]` sets the per-contract
  timeout and how many run at once - see `Rujira.Enum`. Without a `:height`
  this is the memoized `list/2`, so a per-call `:fan_out` only applies to an
  uncached read.
  """
  @spec list(module(), list(integer()), Node.opts()) ::
          {:ok, list(struct())} | {:error, Node.rpc_error()}
  def list(module, code_ids, opts) when is_list(code_ids) do
    Node.at_height(
      opts,
      fn -> fetch_list(module, code_ids, opts) end,
      fn -> list(module, code_ids) end
    )
  end

  @doc """
  True when a wasm query error means the queried item does not exist.

  The node wraps a contract error as gRPC status 2 with the message
  `"<contract error>: query wasm contract failed"`, so the accepted forms are
  the renderings of the two "not found" errors a queried Rujira contract can
  raise:

    * `"NotFound"` - FIN's own `ContractError::NotFound {}`
      (`contracts/rujira-fin/src/error.rs:70`), raised when an order is missing
      (`contracts/rujira-fin/src/order_pool/order.rs:34`) and when a range is
      (`contracts/rujira-fin/src/ranges/query.rs:11`, reached for a fixed and a
      dynamic range alike).

    * `"<kind> not found"` - `cosmwasm_std::StdError::NotFound`, whose `kind`
      `cw-storage-plus` builds as `"type: <rust type>; key: [<hex bytes>]"`, so
      the whole message reads `"type: rujira_rs::account_pool::AccountPoolAccount;
      key: [..] not found"`. This is what the staking account query returns for
      an address that has never bonded - the bare `ACCOUNTS.load/2` at
      `contracts/rujira-staking/src/state.rs:203`, surfaced unchanged because
      that query returns `StdResult`
      (`contracts/rujira-staking/src/contract.rs:234`).

  Everything else is false: any other contract error, any other gRPC status, and
  any term that is not a `GRPC.RPCError` - a transport failure included.
  """
  @spec not_found?(term()) :: boolean()
  def not_found?(%GRPC.RPCError{status: 2, message: message}) when is_binary(message) do
    case String.split(message, @wasm_query_failed, parts: 2) do
      [contract_error, ""] -> not_found_error?(contract_error)
      _ -> false
    end
  end

  def not_found?(_), do: false

  @spec query_state_raw(String.t(), binary(), Node.opts()) ::
          {:ok, term()} | {:error, :not_found} | {:error, Node.rpc_error()}
  def query_state_raw(address, query, opts \\ []) do
    case Node.query(
           &Stub.raw_contract_state/3,
           %QueryRawContractStateRequest{
             address: address,
             query_data: query
           },
           opts
         ) do
      {:ok, %{data: ""}} -> {:error, :not_found}
      {:ok, %{data: data}} -> JSON.decode(data)
      other -> other
    end
  end

  @spec query_state_smart(String.t(), map(), Node.opts()) ::
          {:ok, term()} | {:error, Node.rpc_error()}
  def query_state_smart(address, query, opts \\ []) do
    with {:ok, %{data: data}} <-
           Node.query(
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

  `key` missing from the reply, or present with a non-list value, is a
  malformed reply rather than an empty page: `{:error, :invalid_response}`.
  """
  @spec paginate(
          {:ok, map()} | {:error, any()},
          String.t(),
          pos_integer(),
          (list() -> {:ok, list()} | {:error, any()})
        ) :: {:ok, list()} | {:error, any()}
  def paginate(result, key, limit, next_fn)

  def paginate({:ok, %{} = res}, key, limit, next_fn) do
    case Map.fetch(res, key) do
      {:ok, items} when is_list(items) -> paginate_page(items, limit, next_fn)
      _ -> {:error, :invalid_response}
    end
  end

  def paginate(err, _, _, _), do: err

  defp paginate_page(items, limit, next_fn) when length(items) == limit do
    with {:ok, next} <- next_fn.(items), do: {:ok, items ++ next}
  end

  defp paginate_page(items, _limit, _next_fn), do: {:ok, items}

  @doc "Queries the full, raw contract state at an address"
  @spec query_state_all(String.t()) ::
          {:ok, map()} | {:error, Node.rpc_error()}
  defmemo query_state_all(address) do
    query_state_all_page(address, nil, [])
  end

  @doc "As `query_state_all/1`, read at `opts[:height]` when given."
  @spec query_state_all(String.t(), Node.opts()) :: {:ok, map()} | {:error, Node.rpc_error()}
  def query_state_all(address, opts) do
    Node.at_height(
      opts,
      fn -> query_state_all_page(address, nil, opts) end,
      fn -> query_state_all(address) end
    )
  end

  defp query_state_all_page(address, page, opts) do
    with {:ok, %{models: models, pagination: %{next_key: next_key}}} when next_key != "" <-
           Node.query(
             &Stub.all_contract_state/3,
             %QueryAllContractStateRequest{address: address, pagination: page},
             opts
           ),
         {:ok, next} <-
           query_state_all_page(address, %PageRequest{key: next_key}, opts) do
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
  @spec stream_state_all(String.t(), Node.opts()) :: Enumerable.t()
  def stream_state_all(address, opts \\ []) do
    Stream.resource(
      fn ->
        Node.query(
          &Stub.all_contract_state/3,
          %QueryAllContractStateRequest{address: address},
          opts
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
            Node.query(
              &Stub.all_contract_state/3,
              %QueryAllContractStateRequest{
                address: address,
                pagination: %PageRequest{key: next_key}
              },
              opts
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

  @spec query_state_smart_with_retry(String.t(), map(), Node.opts()) ::
          {:ok, map()} | {:error, term()}
  def query_state_smart_with_retry(address, query, opts \\ []) do
    case query_state_smart(address, query, opts) |> log_retry(address, query) do
      {:error, %GRPC.RPCError{status: 2, message: msg}}
      when msg in [
             "Invalid layer 1 string : query wasm contract failed",
             "codespace wasm code 29: wasmvm error: Error calling the VM: Error executing Wasm: Wasmer runtime error: RuntimeError: Error calling into the VM's backend: Panic in FFI call",
             "Generic error: Parsing u128: cannot parse integer from empty string: query wasm contract failed",
             "failed to decode Protobuf message: invalid tag value: 0: query wasm contract failed",
             "Generic error: Parsing u128: invalid digit found in string: query wasm contract failed",
             "Generic error: Error parsing whole: query wasm contract failed"
           ] ->
        query_state_smart(address, query, opts)

      other ->
        other
    end
  end

  # --- Private ---

  defp not_found_error?("NotFound"), do: true
  defp not_found_error?(message), do: String.ends_with?(message, " not found")

  defp fetch_code_info(code_id, opts) do
    with {:ok, %{code_info: code_info}} <-
           Node.query(&Stub.code/3, %QueryCodeRequest{code_id: code_id}, opts) do
      {:ok, code_info}
    end
  end

  defp fetch_version(address, opts) do
    case query_state_raw(address, :erlang.iolist_to_binary("contract_info"), opts) do
      {:ok, %{"contract" => contract, "version" => version}} ->
        {:ok, %{contract: contract, version: version}}

      {:error, %{message: "codespace wasm code 22: no such contract:" <> _}} ->
        {:error, :not_found}

      other ->
        other
    end
  end

  defp fetch_build_address(salt, creator, id, opts) when is_integer(id) do
    with {:ok, %{data_hash: data_hash}} <- code_info(id, opts) do
      fetch_build_address(salt, creator, Base.encode16(data_hash), opts)
    end
  end

  defp fetch_build_address(salt, creator, hash, opts) do
    with {:ok, %{address: address}} <-
           Node.query(
             &Stub.build_address/3,
             %QueryBuildAddressRequest{
               code_hash: hash,
               creator_address: creator,
               salt: salt
             },
             opts
           ) do
      {:ok, address}
    end
  end

  defp fetch_build_address!(salt, deployer, code_id, opts) do
    {:ok, address} = build_address(salt, deployer, code_id, opts)
    address
  end

  defp fetch_info(address, opts) do
    with {:ok, %{contract_info: contract_info}} <-
           Node.query(
             &Stub.contract_info/3,
             %QueryContractInfoRequest{address: address},
             opts
           ) do
      {:ok, contract_info}
    end
  end

  defp codes_page("", _opts), do: {:ok, []}

  defp codes_page(key, opts) do
    with {:ok, %{code_infos: code_infos, pagination: %{next_key: next_key}}} <-
           Node.query(&Stub.codes/3, %QueryCodesRequest{pagination: page_request(key)}, opts),
         {:ok, next} <- codes_page(next_key, opts) do
      {:ok, Enum.concat(code_infos, next)}
    end
  end

  defp fetch_by_code(code_id, opts) do
    with {:ok, contracts} <- by_code_page(code_id, nil, opts) do
      {:ok, Enum.map(contracts, &%__MODULE__{id: &1, address: &1})}
    end
  end

  defp by_code_page(_code_id, "", _opts), do: {:ok, []}

  defp by_code_page(code_id, key, opts) do
    with {:ok, %{contracts: contracts, pagination: %{next_key: next_key}}} <-
           Node.query(
             &Stub.contracts_by_code/3,
             %QueryContractsByCodeRequest{code_id: code_id, pagination: page_request(key)},
             opts
           ),
         {:ok, next} <- by_code_page(code_id, next_key, opts) do
      {:ok, Enum.concat(contracts, next)}
    end
  end

  defp fetch_get(module, address, opts) do
    case query_state_smart(address, %{config: %{}}, opts) do
      {:ok, config} ->
        construct(module, address, config)

      {:error, err} ->
        if no_contract?(err) or not_found?(err), do: {:error, :not_found}, else: {:error, err}
    end
  end

  defp no_contract?(%GRPC.RPCError{status: 2, message: message}) when is_binary(message) do
    String.contains?(message, "no such contract")
  end

  defp no_contract?(_), do: false

  defp fetch_list(module, code_ids, opts) do
    with {:ok, contracts} <- by_codes(code_ids, opts) do
      Rujira.Enum.reduce_async_while_ok(contracts, &get({module, &1}, opts), opts, __MODULE__)
    end
  end

  defp page_request(nil), do: nil
  defp page_request(key), do: %PageRequest{key: key}

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
