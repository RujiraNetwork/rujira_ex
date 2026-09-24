defmodule Rujira.ThorchainSwap.Strategy do
  @moduledoc """
  A rujira-thorchain-swap streaming market-maker strategy.

  Struct, construction, and queries. Use `Rujira.ThorchainSwap` as the public API.
  """

  alias Rujira.Amount
  alias Rujira.Assets
  alias Rujira.Assets.Asset
  alias Rujira.Contracts
  alias Rujira.Deployments
  alias Rujira.Math

  use Memoize

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

  @spec get(String.t()) :: {:ok, t()} | {:error, term()}
  def get(address), do: Contracts.get({__MODULE__, address})

  @spec list() :: {:ok, [t()]} | {:error, term()}
  def list do
    __MODULE__
    |> Deployments.list_targets()
    |> Rujira.Enum.reduce_async_while_ok(fn %{address: address} ->
      Contracts.get({__MODULE__, address})
    end)
  end

  @doc """
  Loads the strategy's live `markets` and `vaults` into its fields.

  Both are memoized on `address`. Invalidate with:

      Memoize.invalidate(Rujira.ThorchainSwap.Strategy, :query_markets, [address])
      Memoize.invalidate(Rujira.ThorchainSwap.Strategy, :query_vaults, [address])
  """
  @spec load(t()) :: {:ok, t()} | {:error, term()}
  def load(%__MODULE__{address: address} = strategy) do
    with {:ok, markets} <- query_markets(address),
         {:ok, vaults} <- query_vaults(address) do
      {:ok, %{strategy | markets: markets, vaults: vaults}}
    end
  end

  # --- Private ---

  @spec query_markets(String.t()) :: {:ok, [String.t()]} | {:error, term()}
  defmemo query_markets(address) do
    with {:ok, %{"markets" => markets}} <- Contracts.query_state_smart(address, %{markets: %{}}) do
      {:ok, markets}
    end
  end

  @spec query_vaults(String.t()) :: {:ok, [Vault.t()]} | {:error, term()}
  defmemo query_vaults(address) do
    with {:ok, %{"vaults" => vaults}} <- Contracts.query_state_smart(address, %{vaults: %{}}) do
      Rujira.Enum.reduce_while_ok(vaults, [], &vault/1)
    end
  end

  defp vault(%{"denom" => denom, "vault" => address}) do
    with {:ok, asset} <- Assets.from_denom(denom) do
      {:ok, %Vault{asset: asset, address: address}}
    end
  end

  defp vault(_), do: {:error, :invalid_attrs}
end
