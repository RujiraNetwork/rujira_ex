defmodule Rujira.Contracts do
  @moduledoc """
  Convenience methods for querying CosmWasm smart contracts.

  ## Query options

  Every query takes a trailing `opts`, forwarded to `Rujira.Node.query/3`, so a
  caller can read a whole composite at one `height:`.

  Every lookup here is cached per `Rujira.Cache`, resolved at `opts[:height]`
  or - without one - at the head. The no-opts arity is the opts arity with
  `[]`, so it reads at the head. The primitives (`query_state_raw/3`,
  `query_state_smart/3`, `query_state_smart_with_retry/3`,
  `stream_state_all/2`) are the raw node reads every cached lookup is built on
  and are never cached themselves.
  """
  alias Cosmos.Base.Query.V1beta1.PageRequest
  alias Cosmwasm.Wasm.V1.CodeInfoResponse
  alias Cosmwasm.Wasm.V1.ContractInfo
  alias Cosmwasm.Wasm.V1.Model
  alias Cosmwasm.Wasm.V1.Query.Stub
  alias Cosmwasm.Wasm.V1.QueryAllContractStateRequest
  alias Cosmwasm.Wasm.V1.QueryBuildAddressRequest
  alias Cosmwasm.Wasm.V1.QueryCodeRequest
  alias Cosmwasm.Wasm.V1.QueryCodesRequest
  alias Cosmwasm.Wasm.V1.QueryContractInfoRequest
  alias Cosmwasm.Wasm.V1.QueryContractsByCodeRequest
  alias Cosmwasm.Wasm.V1.QueryRawContractStateRequest
  alias Cosmwasm.Wasm.V1.QuerySmartContractStateRequest
  alias Rujira.Cache
  alias Rujira.Logger
  alias Rujira.Node

  # The node's suffix on every contract error raised while answering a wasm query.
  @wasm_query_failed ": query wasm contract failed"

  defstruct id: nil, address: nil, info: nil

  @type t :: %__MODULE__{id: String.t(), address: String.t(), info: ContractInfo.t() | nil}

  @spec from_id(String.t()) :: {:ok, t()}
  def from_id(id) do
    {:ok, %__MODULE__{id: id, address: id}}
  end

  @doc """
  The code stored under `code_id`.

  A `code_id` the node holds no code for is `{:error, :not_found}`, cached as
  the fact it is until the code registry changes.
  """
  @spec code_info(non_neg_integer()) ::
          {:ok, CodeInfoResponse.t()} | {:error, :not_found} | {:error, Node.rpc_error()}
  def code_info(code_id), do: code_info(code_id, [])

  @doc "As `code_info/1`, read at `opts[:height]` when given."
  @spec code_info(non_neg_integer(), Node.opts()) ::
          {:ok, CodeInfoResponse.t()} | {:error, :not_found} | {:error, Node.rpc_error()}
  def code_info(code_id, opts) do
    with {:ok, opts} <- Cache.pin(opts),
         {:ok, value} <-
           Cache.fetch(
             {__MODULE__, :code_info, [code_id]},
             &code_info_sources/1,
             opts,
             fn _height -> fetch_code_info(code_id, opts) end
           ) do
      found(value)
    end
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
  def version(address), do: version(address, [])

  @doc "As `version/1`, read at `opts[:height]` when given."
  @spec version(String.t(), Node.opts()) ::
          {:ok, %{contract: String.t(), version: String.t()}}
          | {:error, :not_found}
          | {:error, term()}
  def version(address, opts) do
    with {:ok, opts} <- Cache.pin(opts) do
      Cache.fetch(
        {__MODULE__, :version, [address]},
        [{:contract, address}],
        opts,
        fn _height -> fetch_version(address, opts) end
      )
    end
  end

  @spec build_address(binary(), String.t(), non_neg_integer() | String.t()) ::
          {:ok, String.t()} | {:error, term()}
  def build_address(salt, creator, id), do: build_address(salt, creator, id, [])

  @doc """
  As `build_address/3`, read at `opts[:height]` when given.

  A code id is resolved to its data hash through `code_info/2`, at that height;
  the address the hash builds depends on nothing else, so it is an identity
  fact and both forms share one cached row.
  """
  @spec build_address(binary(), String.t(), non_neg_integer() | String.t(), Node.opts()) ::
          {:ok, String.t()} | {:error, term()}
  def build_address(salt, creator, id, opts) when is_integer(id) do
    with {:ok, opts} <- Cache.pin(opts),
         {:ok, %{data_hash: data_hash}} <- code_info(id, opts) do
      build_address(salt, creator, Base.encode16(data_hash), opts)
    end
  end

  def build_address(salt, creator, hash, opts) do
    Cache.fetch(
      {__MODULE__, :build_address, [salt, creator, hash]},
      :identity,
      opts,
      fn _height -> fetch_build_address(salt, creator, hash, opts) end
    )
  end

  @spec build_address!(binary(), String.t(), non_neg_integer() | String.t()) :: String.t()
  def build_address!(salt, deployer, code_id), do: build_address!(salt, deployer, code_id, [])

  @doc "As `build_address!/3`, read at `opts[:height]` when given."
  @spec build_address!(binary(), String.t(), non_neg_integer() | String.t(), Node.opts()) ::
          String.t()
  def build_address!(salt, deployer, code_id, opts) do
    {:ok, address} = build_address(salt, deployer, code_id, opts)
    address
  end

  @spec info(String.t()) ::
          {:ok, ContractInfo.t()} | {:error, Node.rpc_error()}
  def info(address), do: info(address, [])

  @doc "As `info/1`, read at `opts[:height]` when given."
  @spec info(String.t(), Node.opts()) :: {:ok, ContractInfo.t()} | {:error, Node.rpc_error()}
  def info(address, opts) do
    with {:ok, opts} <- Cache.pin(opts) do
      Cache.fetch(
        {__MODULE__, :info, [address]},
        [{:contract, address}],
        opts,
        fn _height -> fetch_info(address, opts) end
      )
    end
  end

  @spec codes() :: {:ok, list(CodeInfoResponse.t())} | {:error, Node.rpc_error()}
  def codes, do: codes([])

  @doc "As `codes/0`, read at `opts[:height]` when given."
  @spec codes(Node.opts()) :: {:ok, list(CodeInfoResponse.t())} | {:error, Node.rpc_error()}
  def codes(opts) do
    with {:ok, opts} <- Cache.pin(opts) do
      Cache.fetch({__MODULE__, :codes, []}, [:contract_registry], opts, fn _height ->
        codes_page(nil, opts)
      end)
    end
  end

  @spec by_code(integer()) ::
          {:ok, list(t())} | {:error, Node.rpc_error()}
  def by_code(code_id), do: by_code(code_id, [])

  @doc "As `by_code/1`, read at `opts[:height]` when given."
  @spec by_code(integer(), Node.opts()) :: {:ok, list(t())} | {:error, Node.rpc_error()}
  def by_code(code_id, opts) do
    with {:ok, opts} <- Cache.pin(opts) do
      Cache.fetch(
        {__MODULE__, :by_code, [code_id]},
        [:contract_registry],
        opts,
        fn _height -> fetch_by_code(code_id, opts) end
      )
    end
  end

  @spec by_codes(list(integer()), Node.opts()) ::
          {:ok, list(t())} | {:error, Node.rpc_error()}
  def by_codes(code_ids, opts \\ []) do
    with {:ok, opts} <- Cache.pin(opts) do
      Enum.reduce(code_ids, {:ok, []}, &append_by_code(&1, &2, opts))
    end
  end

  @doc """
  Loads `module`'s config from the contract at `address` and constructs it.

  An `address` that holds no contract, or a contract the node otherwise
  reports as missing, is `{:error, :not_found}`.
  """
  @spec get({module(), String.t() | __MODULE__.t()} | struct()) ::
          {:ok, struct()} | {:error, :not_found} | {:error, any()}
  def get(target), do: get(target, [])

  @doc "As `get/1`, read at `opts[:height]` when given."
  @spec get({module(), String.t() | t()} | struct(), Node.opts()) ::
          {:ok, struct()} | {:error, :not_found} | {:error, any()}
  def get({module, %__MODULE__{address: address}}, opts), do: get({module, address}, opts)

  def get({module, address}, opts) do
    with {:ok, opts} <- Cache.pin(opts) do
      Cache.fetch(
        {__MODULE__, :get, [module, address]},
        [{:contract, address}],
        opts,
        fn _height -> fetch_get(module, address, opts) end
      )
    end
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
  def list(module, code_ids) when is_list(code_ids), do: list(module, code_ids, [])

  @doc """
  As `list/2`, read at `opts[:height]` when given.

  Each contract is read concurrently; `opts[:fan_out]` sets the per-contract
  timeout and how many run at once - see `Rujira.Enum`. The list is cached
  against the code registry and against every contract it resolved, so one
  contract's event invalidates it.
  """
  @spec list(module(), list(integer()), Node.opts()) ::
          {:ok, list(struct())} | {:error, Node.rpc_error()}
  def list(module, code_ids, opts) when is_list(code_ids) do
    with {:ok, opts} <- Cache.pin(opts) do
      Cache.fetch(
        {__MODULE__, :list, [module, code_ids]},
        &list_sources/1,
        opts,
        fn _height -> fetch_list(module, code_ids, opts) end
      )
    end
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

  @doc """
  Queries the full, raw contract state at an address.

  A whole contract's state is too large to hold, so this is the one read here
  that is never cached. It still resolves its height like every other: at
  `opts[:height]`, or at the head.
  """
  @spec query_state_all(String.t()) ::
          {:ok, map()} | {:error, Node.rpc_error()}
  def query_state_all(address), do: query_state_all(address, [])

  @doc "As `query_state_all/1`, read at `opts[:height]` when given."
  @spec query_state_all(String.t(), Node.opts()) :: {:ok, map()} | {:error, Node.rpc_error()}
  def query_state_all(address, opts) do
    with {:ok, opts} <- Cache.pin(opts) do
      query_state_all_page(address, nil, opts)
    end
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

  # The code a stored id holds never changes, so a found code is only ever
  # invalidated by a reset; whether an id resolves at all is the code
  # registry's business.
  defp code_info_sources(:none), do: [:contract_registry]
  defp code_info_sources(_code_info), do: []

  defp found(:none), do: {:error, :not_found}
  defp found(value), do: {:ok, value}

  # gRPC `NOT_FOUND` is the node saying it holds no code under the id - a fact
  # about the registry, not a failed read.
  defp fetch_code_info(code_id, opts) do
    case Node.query(&Stub.code/3, %QueryCodeRequest{code_id: code_id}, opts) do
      {:ok, %{code_info: code_info}} -> {:ok, code_info}
      {:error, %GRPC.RPCError{status: 5}} -> {:ok, :none}
      other -> other
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

  # A list is only as valid as the registry it was read from and every
  # contract it resolved; a member with no binary address would otherwise
  # silently lose its own invalidation source, so this fails loudly instead.
  defp list_sources(contracts) do
    [:contract_registry | Enum.map(contracts, &contract_source/1)]
  end

  defp contract_source(%{address: a}) when is_binary(a), do: {:contract, a}

  defp contract_source(other),
    do:
      raise(
        ArgumentError,
        "Contracts.list/3 resolved a contract with no binary address: #{inspect(other)}"
      )

  defp fetch_list(module, code_ids, opts) do
    with {:ok, contracts} <- by_codes(code_ids, opts) do
      Rujira.Enum.reduce_async_while_ok(contracts, &get({module, &1}, opts), opts, __MODULE__)
    end
  end

  defp append_by_code(code_id, {:ok, agg}, opts) do
    with {:ok, contracts} <- by_code(code_id, opts), do: {:ok, agg ++ contracts}
  end

  defp append_by_code(_code_id, err, _opts), do: err

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
