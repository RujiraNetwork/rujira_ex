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
  alias Rujira.Cache
  alias Rujira.Coin
  alias Rujira.Contracts
  alias Rujira.Math
  alias Rujira.Node

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
  `{:error, :not_found}` - a fact about the maker, cached as one until the next
  block.

  Cached per `Rujira.Cache`, resolved at `opts[:height]` or - without one - at
  the head. A quote is priced off the book and the oracle, neither of which
  announces itself with an event, so it is read per block. The assets are
  resolved to their native denoms and `min_price` to the string that goes on the
  wire before the cache is keyed, so equal decimals (`1.5` and `1.50`) are the
  one read.
  """
  @spec query(String.t(), Asset.t(), Asset.t(), Decimal.t() | nil, Node.opts()) ::
          {:ok, t()} | {:error, term()}
  def query(address, %Asset{} = offer, %Asset{} = ask, min_price \\ nil, opts \\ []) do
    min_price = wire_min_price(min_price)

    with {:ok, opts} <- Cache.pin(opts),
         {:ok, offer_denom} <- Assets.to_native(offer),
         {:ok, ask_denom} <- Assets.to_native(ask),
         {:ok, res} <-
           Cache.fetch(
             {__MODULE__, :query, [address, offer_denom, ask_denom, min_price]},
             [:per_block],
             opts,
             fn _height -> fetch(address, offer_denom, ask_denom, min_price, opts) end
           ) do
      new(%{address: address, offer: offer, ask: ask}, res)
    end
  end

  # --- Private ---

  defp fetch(address, offer_denom, ask_denom, min_price, opts) do
    Contracts.query_state_smart(
      address,
      %{
        quote: %{
          min_price: min_price,
          offer_denom: offer_denom,
          ask_denom: ask_denom,
          data: nil
        }
      },
      opts
    )
  end

  # The wire form is the key: `Decimal.normalize/1` first, so `1.50` and `1.5`
  # are the one price on the wire and in the cache alike.
  defp wire_min_price(nil), do: nil

  defp wire_min_price(%Decimal{} = value),
    do: value |> Decimal.normalize() |> Decimal.to_string(:normal)
end
