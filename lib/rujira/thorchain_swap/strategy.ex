defmodule Rujira.ThorchainSwap.Strategy do
  @moduledoc """
  A rujira-thorchain-swap streaming market-maker strategy.

  Struct, construction, and queries. Use `Rujira.ThorchainSwap` as the public API.
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
            spread_bps: 0,
            max_borrow_ratio: Decimal.new(0),
            min_borrow_amount: 0,
            reserve_fee: Decimal.new(0),
            fee: Decimal.new(0),
            fee_address: nil,
            markets: :not_loaded,
            vaults: :not_loaded

  @type t :: %__MODULE__{
          id: String.t() | nil,
          address: String.t() | nil,
          max_stream_length: non_neg_integer(),
          stream_step_ratio: Decimal.t(),
          spread_bps: non_neg_integer(),
          max_borrow_ratio: Decimal.t(),
          min_borrow_amount: Amount.t(),
          reserve_fee: Decimal.t(),
          fee: Decimal.t(),
          fee_address: String.t() | nil,
          markets: :not_loaded | [String.t()],
          vaults: :not_loaded | [Vault.t()]
        }

  # --- Construction ---

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{
        "address" => address,
        "max_stream_length" => max_stream_length,
        "stream_step_ratio" => stream_step_ratio,
        "spread_bps" => spread_bps,
        "max_borrow_ratio" => max_borrow_ratio,
        "min_borrow_amount" => min_borrow_amount,
        "reserve_fee" => reserve_fee,
        "fee" => [fee, fee_address]
      }) do
    with {:ok, max_stream_length} <- Math.to_integer(max_stream_length),
         {:ok, stream_step_ratio} <- Math.to_decimal(stream_step_ratio),
         {:ok, spread_bps} <- Math.to_integer(spread_bps),
         {:ok, max_borrow_ratio} <- Math.to_decimal(max_borrow_ratio),
         {:ok, min_borrow_amount} <- Amount.new(min_borrow_amount),
         {:ok, reserve_fee} <- Math.to_decimal(reserve_fee),
         {:ok, fee} <- Math.to_decimal(fee) do
      {:ok,
       %__MODULE__{
         id: address,
         address: address,
         max_stream_length: max_stream_length,
         stream_step_ratio: stream_step_ratio,
         spread_bps: spread_bps,
         max_borrow_ratio: max_borrow_ratio,
         min_borrow_amount: min_borrow_amount,
         reserve_fee: reserve_fee,
         fee: fee,
         fee_address: fee_address
       }}
    end
  end

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

  @doc "Loads the strategy's live `markets` and `vaults` into its fields."
  @spec load(t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def load(%__MODULE__{address: address} = strategy, opts \\ []) do
    with {:ok, markets} <- query_markets(address, opts),
         {:ok, vaults} <- query_vaults(address, opts) do
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
