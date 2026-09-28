defmodule Rujira.Revenue.Converter do
  @moduledoc """
  A rujira-revenue converter, distributing collected protocol fees.

  Struct, construction, and queries. Use `Rujira.Revenue` as the public API.

  Parses both live contract versions, v1.1.0 and v2.x. A v1.1.0 config has
  no `schedule` and no `last_executed`, and its target denoms carry no
  per-denom cap, so `schedule`, `last_executed`, and
  `TargetDenom.max_per_second` are all `nil` on a v1.1.0 converter. A
  v1.1.0 action's cap is wire-named `limit`; this library exposes it as
  `Action.max`, leaving `Action.min` `nil` (v1 has no floor).
  """

  alias Rujira.Amount
  alias Rujira.Assets
  alias Rujira.Assets.Asset
  alias Rujira.Contracts
  alias Rujira.Deployments
  alias Rujira.Math
  alias Rujira.Node

  use Memoize

  defmodule TargetDenom do
    @moduledoc "A target denom distributed to target_addresses each run, capped at max_per_second times the seconds elapsed since last_executed. `max_per_second` is nil on a v1.1.0 converter, which has no per-denom cap."
    defstruct asset: nil, max_per_second: nil
    @type t :: %__MODULE__{asset: Asset.t(), max_per_second: Amount.t() | nil}
  end

  defmodule TargetAddress do
    @moduledoc "A payout address and its weight in the converter's distribution."
    defstruct address: nil, weight: 0
    @type t :: %__MODULE__{address: String.t(), weight: non_neg_integer()}
  end

  defmodule Action do
    @moduledoc "A configured swap step from one collected denom to the converter's target token. `min` is nil on a v1.1.0 converter, whose wire calls the cap `limit`; this library exposes it as `max`."
    defstruct asset: nil, contract: nil, min: nil, max: 0, msg: nil

    @type t :: %__MODULE__{
            asset: Asset.t(),
            contract: String.t(),
            min: Amount.t() | nil,
            max: Amount.t(),
            msg: binary()
          }
  end

  # --- Struct ---

  defstruct id: nil,
            address: nil,
            owner: nil,
            executor: nil,
            target_denoms: [],
            target_addresses: [],
            schedule: nil,
            last_executed: nil,
            actions: :not_loaded,
            last_action: :not_loaded

  @type t :: %__MODULE__{
          id: String.t() | nil,
          address: String.t() | nil,
          owner: String.t() | nil,
          executor: String.t() | nil,
          target_denoms: [TargetDenom.t()],
          target_addresses: [TargetAddress.t()],
          schedule: non_neg_integer() | nil,
          last_executed: DateTime.t() | nil,
          actions: :not_loaded | [Action.t()],
          last_action: :not_loaded | Asset.t() | nil
        }

  # --- Construction ---

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{
        "address" => address,
        "owner" => owner,
        "executor" => executor,
        "target_denoms" => target_denoms,
        "target_addresses" => target_addresses,
        "schedule" => schedule,
        "last_executed" => last_executed
      }) do
    with {:ok, target_denoms} <-
           Rujira.Enum.reduce_while_ok(target_denoms, [], &target_denom/1),
         {:ok, target_addresses} <-
           Rujira.Enum.reduce_while_ok(target_addresses, [], &target_address/1),
         {:ok, schedule} <- Math.to_integer(schedule),
         {:ok, last_executed} <- Math.to_integer(last_executed),
         {:ok, last_executed} <- parse_timestamp(last_executed) do
      {:ok,
       %__MODULE__{
         id: address,
         address: address,
         owner: owner,
         executor: executor,
         target_denoms: target_denoms,
         target_addresses: target_addresses,
         schedule: schedule,
         last_executed: last_executed
       }}
    end
  end

  def new(
        %{
          "address" => address,
          "owner" => owner,
          "executor" => executor,
          "target_denoms" => target_denoms,
          "target_addresses" => target_addresses
        } = attrs
      )
      when not is_map_key(attrs, "schedule") and not is_map_key(attrs, "last_executed") do
    with {:ok, target_denoms} <-
           Rujira.Enum.reduce_while_ok(target_denoms, [], &target_denom_v1/1),
         {:ok, target_addresses} <-
           Rujira.Enum.reduce_while_ok(target_addresses, [], &target_address/1) do
      {:ok,
       %__MODULE__{
         id: address,
         address: address,
         owner: owner,
         executor: executor,
         target_denoms: target_denoms,
         target_addresses: target_addresses,
         schedule: nil,
         last_executed: nil
       }}
    end
  end

  def new(_), do: {:error, :invalid_attrs}

  # --- Queries ---

  @spec get(String.t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def get(address, opts \\ []), do: Contracts.get({__MODULE__, address}, opts)

  @doc """
  Lists every deployed revenue converter.

  Each converter is read concurrently; `opts[:fan_out]` sets the per-converter
  timeout and how many run at once - see `Rujira.Enum`.
  """
  @spec list(Node.opts()) :: {:ok, [t()]} | {:error, term()}
  def list(opts \\ []) do
    with {:ok, targets} <- Deployments.list_targets(__MODULE__, opts) do
      Rujira.Enum.reduce_async_while_ok(
        targets,
        fn %{address: address} -> Contracts.get({__MODULE__, address}, opts) end,
        opts,
        __MODULE__
      )
    end
  end

  @spec from_id(String.t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def from_id(address, opts \\ []), do: get(address, opts)

  @doc """
  Loads the converter's live `actions` and `last_action` into its fields.

  Both are memoized on `address`. Invalidate with:

      Memoize.invalidate(Rujira.Revenue.Converter, :query_actions, [address])
      Memoize.invalidate(Rujira.Revenue.Converter, :query_status, [address])
  """
  @spec load(t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def load(%__MODULE__{address: address} = converter, opts \\ []) do
    with {:ok, actions} <- query_actions(address, opts),
         {:ok, last_action} <- query_status(address, opts) do
      {:ok, %{converter | actions: actions, last_action: last_action}}
    end
  end

  @spec query_actions(String.t()) :: {:ok, [Action.t()]} | {:error, term()}
  defmemo query_actions(address) do
    fetch_actions(address, [])
  end

  @doc """
  As `query_actions/1`, read at `opts[:height]` when one is given - a height
  read is never cached. Without a `:height` this is `query_actions/1`, so the
  other opts are not applied.
  """
  @spec query_actions(String.t(), Node.opts()) :: {:ok, [Action.t()]} | {:error, term()}
  def query_actions(address, opts) do
    Node.at_height(
      opts,
      fn -> fetch_actions(address, opts) end,
      fn -> query_actions(address) end
    )
  end

  @spec query_status(String.t()) :: {:ok, Asset.t() | nil} | {:error, term()}
  defmemo query_status(address) do
    fetch_status(address, [])
  end

  @doc """
  As `query_status/1`, read at `opts[:height]` when one is given - a height
  read is never cached. Without a `:height` this is `query_status/1`, so the
  other opts are not applied.
  """
  @spec query_status(String.t(), Node.opts()) :: {:ok, Asset.t() | nil} | {:error, term()}
  def query_status(address, opts) do
    Node.at_height(
      opts,
      fn -> fetch_status(address, opts) end,
      fn -> query_status(address) end
    )
  end

  # --- Private ---

  defp fetch_actions(address, opts) do
    with {:ok, %{"actions" => actions}} <-
           Contracts.query_state_smart(address, %{actions: %{}}, opts) do
      Rujira.Enum.reduce_while_ok(actions, [], &action/1)
    end
  end

  defp fetch_status(address, opts) do
    with {:ok, %{"last" => last}} <-
           Contracts.query_state_smart(address, %{status: %{}}, opts) do
      status(last)
    end
  end

  defp target_denom([denom, max_per_second]) do
    with {:ok, asset} <- Assets.from_denom(denom),
         {:ok, max_per_second} <- Amount.new(max_per_second) do
      {:ok, %TargetDenom{asset: asset, max_per_second: max_per_second}}
    end
  end

  defp target_denom(_), do: {:error, :invalid_attrs}

  defp target_denom_v1(denom) when is_binary(denom) do
    with {:ok, asset} <- Assets.from_denom(denom) do
      {:ok, %TargetDenom{asset: asset, max_per_second: nil}}
    end
  end

  defp target_denom_v1(_), do: {:error, :invalid_attrs}

  defp target_address([address, weight]) when is_binary(address) do
    with {:ok, weight} <- Math.to_integer(weight),
         {:ok, weight} <- parse_weight(weight) do
      {:ok, %TargetAddress{address: address, weight: weight}}
    end
  end

  defp target_address(_), do: {:error, :invalid_attrs}

  defp action(%{
         "denom" => denom,
         "contract" => contract,
         "min" => min,
         "max" => max,
         "msg" => msg
       }) do
    with {:ok, asset} <- Assets.from_denom(denom),
         {:ok, min} <- Amount.new(min),
         {:ok, max} <- Amount.new(max),
         {:ok, msg} <- decode_msg(msg) do
      {:ok, %Action{asset: asset, contract: contract, min: min, max: max, msg: msg}}
    end
  end

  defp action(
         %{
           "denom" => denom,
           "contract" => contract,
           "limit" => limit,
           "msg" => msg
         } = attrs
       )
       when not is_map_key(attrs, "min") and not is_map_key(attrs, "max") do
    with {:ok, asset} <- Assets.from_denom(denom),
         {:ok, max} <- Amount.new(limit),
         {:ok, msg} <- decode_msg(msg) do
      {:ok, %Action{asset: asset, contract: contract, min: nil, max: max, msg: msg}}
    end
  end

  defp action(_), do: {:error, :invalid_attrs}

  defp decode_msg(msg) when is_binary(msg) do
    case Base.decode64(msg) do
      {:ok, decoded} -> {:ok, decoded}
      :error -> {:error, :invalid_msg}
    end
  end

  defp decode_msg(_), do: {:error, :invalid_msg}

  defp parse_timestamp(nil), do: {:error, :invalid_integer}
  defp parse_timestamp(ts), do: DateTime.from_unix(ts, :nanosecond)

  defp parse_weight(nil), do: {:error, :invalid_integer}
  defp parse_weight(weight), do: {:ok, weight}

  defp status(nil), do: {:ok, nil}
  defp status(denom), do: Assets.from_denom(denom)
end
