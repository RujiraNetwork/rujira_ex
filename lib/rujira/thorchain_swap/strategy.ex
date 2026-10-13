defmodule Rujira.ThorchainSwap.Strategy do
  @moduledoc """
  A rujira-thorchain-swap streaming market-maker strategy.

  Struct, construction, and queries. Use `Rujira.ThorchainSwap` as the public API.

  Parses every config shape the contract has served. Strategies instantiated
  on early code are never migrated, and a migrated strategy read at an older
  height serves the shape of the code it ran then. Fields a shape does not
  carry are `nil`:

  | Contract          | `min_slip_bps` | `fee`, `fee_address` | `min_borrow_amount` | `spread_bps` |
  | ----------------- | -------------- | -------------------- | ------------------- | ------------ |
  | before v0.0.6     | set            | `nil`                | `nil`               | `nil`        |
  | v0.0.6 to v0.x    | `nil`          | `nil`                | `nil`               | `nil`        |
  | v1.0.x            | `nil`          | set                  | `nil`               | `nil`        |
  | v1.1.x            | `nil`          | set                  | set                 | `nil`        |
  | v1.2.0 and later  | `nil`          | set                  | set                 | set          |

  `Rujira.Contracts.version/2` reads the contract version itself.
  """

  alias Rujira.Amount
  alias Rujira.Assets
  alias Rujira.Assets.Asset
  alias Rujira.Cache
  alias Rujira.Contracts
  alias Rujira.Deployments
  alias Rujira.Math
  alias Rujira.Node

  defmodule Vault do
    @moduledoc "A token's borrow vault, as returned by the strategy's `vaults` query."
    defstruct asset: nil, address: nil
    @type t :: %__MODULE__{asset: Asset.t(), address: String.t()}
  end

  # --- Struct ---

  defstruct id: nil,
            address: nil,
            max_stream_length: 0,
            stream_step_ratio: Decimal.new(0),
            min_slip_bps: nil,
            spread_bps: nil,
            max_borrow_ratio: Decimal.new(0),
            min_borrow_amount: nil,
            reserve_fee: Decimal.new(0),
            fee: nil,
            fee_address: nil,
            markets: :not_loaded,
            vaults: :not_loaded

  @type t :: %__MODULE__{
          id: String.t() | nil,
          address: String.t() | nil,
          max_stream_length: non_neg_integer(),
          stream_step_ratio: Decimal.t(),
          min_slip_bps: non_neg_integer() | nil,
          spread_bps: non_neg_integer() | nil,
          max_borrow_ratio: Decimal.t(),
          min_borrow_amount: Amount.t() | nil,
          reserve_fee: Decimal.t(),
          fee: Decimal.t() | nil,
          fee_address: String.t() | nil,
          markets: :not_loaded | [String.t()],
          vaults: :not_loaded | [Vault.t()]
        }

  # --- Construction ---

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(
        %{
          "spread_bps" => spread_bps,
          "min_borrow_amount" => min_borrow_amount,
          "fee" => [fee, fee_address]
        } = attrs
      )
      when not is_map_key(attrs, "min_slip_bps") do
    with {:ok, spread_bps} <- Math.to_integer(spread_bps),
         {:ok, min_borrow_amount} <- Amount.new(min_borrow_amount),
         {:ok, fee} <- Math.to_decimal(fee) do
      build(attrs,
        spread_bps: spread_bps,
        min_borrow_amount: min_borrow_amount,
        fee: fee,
        fee_address: fee_address
      )
    end
  end

  def new(%{"min_borrow_amount" => min_borrow_amount, "fee" => [fee, fee_address]} = attrs)
      when not is_map_key(attrs, "min_slip_bps") and not is_map_key(attrs, "spread_bps") do
    with {:ok, min_borrow_amount} <- Amount.new(min_borrow_amount),
         {:ok, fee} <- Math.to_decimal(fee) do
      build(attrs, min_borrow_amount: min_borrow_amount, fee: fee, fee_address: fee_address)
    end
  end

  def new(%{"fee" => [fee, fee_address]} = attrs)
      when not is_map_key(attrs, "min_slip_bps") and not is_map_key(attrs, "spread_bps") and
             not is_map_key(attrs, "min_borrow_amount") do
    with {:ok, fee} <- Math.to_decimal(fee) do
      build(attrs, fee: fee, fee_address: fee_address)
    end
  end

  def new(%{"min_slip_bps" => min_slip_bps} = attrs)
      when not is_map_key(attrs, "fee") and not is_map_key(attrs, "spread_bps") and
             not is_map_key(attrs, "min_borrow_amount") do
    with {:ok, min_slip_bps} <- Math.to_integer(min_slip_bps) do
      build(attrs, min_slip_bps: min_slip_bps)
    end
  end

  def new(attrs)
      when is_map(attrs) and not is_map_key(attrs, "min_slip_bps") and
             not is_map_key(attrs, "fee") and not is_map_key(attrs, "spread_bps") and
             not is_map_key(attrs, "min_borrow_amount"),
      do: build(attrs, [])

  def new(_), do: {:error, :invalid_attrs}

  # --- Queries ---

  @spec get(String.t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def get(address, opts \\ []), do: Contracts.get({__MODULE__, address}, opts)

  @doc """
  Lists every deployed swap strategy.

  Each strategy is read concurrently; `opts[:fan_out]` sets the per-strategy
  timeout and how many run at once - see `Rujira.Enum`.
  """
  @spec list(Node.opts()) :: {:ok, [t()]} | {:error, term()}
  def list(opts \\ []) do
    with {:ok, opts} <- Cache.pin(opts),
         {:ok, targets} <- Deployments.list_targets(__MODULE__, opts) do
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

  @doc "Loads the strategy's live `markets` and `vaults` into its fields."
  @spec load(t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def load(%__MODULE__{address: address} = strategy, opts \\ []) do
    with {:ok, opts} <- Cache.pin(opts),
         {:ok, [markets, vaults]} <-
           Rujira.Enum.all_async_while_ok(
             [
               fn -> query_markets(address, opts) end,
               fn -> query_vaults(address, opts) end
             ],
             opts,
             __MODULE__
           ) do
      {:ok, %{strategy | markets: markets, vaults: vaults}}
    end
  end

  @doc "The strategy's live markets, cached per `Rujira.Cache`."
  @spec query_markets(String.t()) :: {:ok, [String.t()]} | {:error, term()}
  def query_markets(address), do: query_markets(address, [])

  @doc """
  As `query_markets/1`, cached per `Rujira.Cache`; resolved at `opts[:height]`
  or the head.
  """
  @spec query_markets(String.t(), Node.opts()) :: {:ok, [String.t()]} | {:error, term()}
  def query_markets(address, opts) do
    with {:ok, opts} <- Cache.pin(opts) do
      Cache.fetch(
        {__MODULE__, :query_markets, [address]},
        [{:contract, address}],
        opts,
        fn _height ->
          fetch_markets(address, opts)
        end
      )
    end
  end

  @doc "The strategy's live vaults, cached per `Rujira.Cache`."
  @spec query_vaults(String.t()) :: {:ok, [Vault.t()]} | {:error, term()}
  def query_vaults(address), do: query_vaults(address, [])

  @doc """
  As `query_vaults/1`, cached per `Rujira.Cache`; resolved at `opts[:height]`
  or the head.
  """
  @spec query_vaults(String.t(), Node.opts()) :: {:ok, [Vault.t()]} | {:error, term()}
  def query_vaults(address, opts) do
    with {:ok, opts} <- Cache.pin(opts) do
      Cache.fetch(
        {__MODULE__, :query_vaults, [address]},
        [{:contract, address}],
        opts,
        fn _height ->
          fetch_vaults(address, opts)
        end
      )
    end
  end

  # --- Private ---

  # The fields every config shape carries. `fields` holds the parsed fields
  # the matching `new/1` clause's shape adds.
  defp build(
         %{
           "address" => address,
           "max_stream_length" => max_stream_length,
           "stream_step_ratio" => stream_step_ratio,
           "max_borrow_ratio" => max_borrow_ratio,
           "reserve_fee" => reserve_fee
         },
         fields
       ) do
    with {:ok, max_stream_length} <- Math.to_integer(max_stream_length),
         {:ok, stream_step_ratio} <- Math.to_decimal(stream_step_ratio),
         {:ok, max_borrow_ratio} <- Math.to_decimal(max_borrow_ratio),
         {:ok, reserve_fee} <- Math.to_decimal(reserve_fee) do
      {:ok,
       struct(
         %__MODULE__{
           id: address,
           address: address,
           max_stream_length: max_stream_length,
           stream_step_ratio: stream_step_ratio,
           max_borrow_ratio: max_borrow_ratio,
           reserve_fee: reserve_fee
         },
         fields
       )}
    end
  end

  defp build(_attrs, _fields), do: {:error, :invalid_attrs}

  defp fetch_markets(address, opts) do
    case Contracts.query_state_smart(address, %{markets: %{}}, opts) do
      {:ok, %{"markets" => markets}} -> {:ok, markets}
      {:ok, _} -> {:error, :invalid_response}
      {:error, _} = err -> err
    end
  end

  defp fetch_vaults(address, opts) do
    case Contracts.query_state_smart(address, %{vaults: %{}}, opts) do
      {:ok, %{"vaults" => vaults}} -> Rujira.Enum.reduce_while_ok(vaults, [], &vault/1)
      {:ok, _} -> {:error, :invalid_response}
      {:error, _} = err -> err
    end
  end

  defp vault(%{"denom" => denom, "vault" => address}) do
    with {:ok, asset} <- Assets.from_denom(denom) do
      {:ok, %Vault{asset: asset, address: address}}
    end
  end

  defp vault(_), do: {:error, :invalid_attrs}
end
