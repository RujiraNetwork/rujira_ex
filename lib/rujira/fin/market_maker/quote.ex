defmodule Rujira.Fin.MarketMaker.Quote do
  @moduledoc """
  A market-maker quote for swapping `offer` into `ask`.

  Served by the shared `{"quote": {...}}` query implemented identically by
  both `rujira-thorchain-swap` and `rujira-brune` contracts, hence this module
  is shared rather than owned by either protocol.

  Struct, construction, and queries. Use each protocol's own facade
  (`Rujira.ThorchainSwap`, etc.) as the public API.
  """

  alias Rujira.Amount
  alias Rujira.Assets
  alias Rujira.Assets.Asset
  alias Rujira.Coin
  alias Rujira.Contracts
  alias Rujira.Math

  use Memoize

  # --- Struct ---

  defstruct address: nil, offer: nil, ask: nil, price: Decimal.new(0), size: nil

  @type t :: %__MODULE__{
          address: String.t() | nil,
          offer: Asset.t() | nil,
          ask: Asset.t() | nil,
          price: Decimal.t(),
          size: Coin.t() | nil
        }

  # --- Construction ---

  @spec new(map(), map() | nil) :: {:ok, t()} | {:error, term()}
  def new(
        %{address: address, offer: %Asset{} = offer, ask: %Asset{} = ask},
        %{"price" => price, "size" => size}
      ) do
    with {:ok, price} <- Math.to_decimal(price),
         {:ok, size} <- Amount.new(size) do
      {:ok,
       %__MODULE__{
         address: address,
         offer: offer,
         ask: ask,
         price: price,
         size: Coin.new(ask, size)
       }}
    end
  end

  # The contract returns `Option<QuoteResponse>`: `null` means nothing to quote.
  def new(_, nil), do: {:error, :not_found}

  def new(_, _), do: {:error, :invalid_attrs}

  # --- Queries ---

  @doc """
  Queries a market maker at `address` for a quote swapping `offer` into
  `ask`, optionally bounded by `min_price`.

  A market maker with nothing to quote (the contract responds `null`) returns
  `{:error, :not_found}`.

  Memoized (privately, as `do_query/4`) on the typed
  `(address, offer, ask, min_price)` tuple. `min_price` is normalised via
  `Decimal.normalize/1` (or left `nil`) so equal decimals (e.g. `1.5` and
  `1.50`) share a cache key. Invalidate with the same normalised value:

      Memoize.invalidate(Rujira.Fin.MarketMaker.Quote, :do_query, [address, offer, ask, min_price && Decimal.normalize(min_price)])
  """
  @spec query(String.t(), Asset.t(), Asset.t(), Decimal.t() | nil) ::
          {:ok, t()} | {:error, term()}
  def query(address, %Asset{} = offer, %Asset{} = ask, min_price \\ nil) do
    do_query(address, offer, ask, normalize_min_price(min_price))
  end

  # --- Private ---

  defmemop do_query(address, %Asset{} = offer, %Asset{} = ask, min_price) do
    with {:ok, offer_denom} <- Assets.to_native(offer),
         {:ok, ask_denom} <- Assets.to_native(ask),
         {:ok, res} <-
           Contracts.query_state_smart(address, %{
             quote: %{
               min_price: min_price && Decimal.to_string(min_price, :normal),
               offer_denom: offer_denom,
               ask_denom: ask_denom,
               data: nil
             }
           }) do
      new(%{address: address, offer: offer, ask: ask}, res)
    end
  end

  defp normalize_min_price(nil), do: nil
  defp normalize_min_price(%Decimal{} = value), do: Decimal.normalize(value)
end
