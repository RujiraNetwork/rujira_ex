defmodule Rujira.Fin.Book do
  @moduledoc """
  Order book for the FIN protocol.

  Struct, construction, and queries. Use `Rujira.Fin` as the public API.
  """

  alias Rujira.Contracts
  alias Rujira.Fin.Pair
  alias Rujira.Logger
  alias Rujira.Math

  use Memoize

  defmodule Price do
    @moduledoc """
    Represents a price level in the order book with associated order details.
    """
    alias Rujira.Amount
    alias Rujira.Math

    defstruct price: Decimal.new(0),
              total: 0,
              side: nil,
              value: 0

    @type side :: :bid | :ask
    @type t :: %__MODULE__{
            price: Decimal.t(),
            total: Amount.t(),
            side: side,
            value: Amount.t()
          }

    @spec new(side, map()) :: {:ok, t()} | {:error, term()}
    def new(side, %{"price" => price_str, "total" => total_str}) when side in [:bid, :ask] do
      with {:ok, price} <- Math.to_decimal(price_str),
           {:ok, total} <- Amount.new(total_str) do
        {:ok,
         %__MODULE__{
           side: side,
           total: total,
           price: price,
           value: value(side, price, total)
         }}
      end
    end

    def new(_, _), do: {:error, :invalid_attrs}

    @spec value(side, Decimal.t(), Amount.t()) :: Amount.t()
    defp value(:ask, price, total) do
      total
      |> Decimal.new()
      |> Decimal.mult(price)
      |> Decimal.round(0, :floor)
      |> Decimal.to_integer()
    end

    defp value(:bid, price, total) do
      total
      |> Decimal.new()
      |> Decimal.div(price)
      |> Decimal.round(0, :floor)
      |> Decimal.to_integer()
    end
  end

  defstruct id: nil,
            bids: [],
            asks: [],
            center: Decimal.new(0),
            spread: Decimal.new(0)

  @type t :: %__MODULE__{
          id: String.t(),
          bids: list(Price.t()),
          asks: list(Price.t()),
          center: Decimal.t(),
          spread: Decimal.t()
        }

  # --- Construction ---

  @spec new(String.t(), map()) :: {:ok, t()} | {:error, term()}
  def new(address, %{"base" => asks, "quote" => bids}) do
    with {:ok, asks} <- Rujira.Enum.reduce_while_ok(asks, &Price.new(:ask, &1)),
         {:ok, bids} <- Rujira.Enum.reduce_while_ok(bids, &Price.new(:bid, &1)) do
      {:ok, %__MODULE__{id: address, asks: asks, bids: bids} |> populate()}
    end
  end

  # --- Queries ---

  @spec load(Pair.t(), integer()) :: {:ok, Pair.t()} | {:error, term()}
  def load(pair, limit \\ 75)

  def load(pair, limit) do
    with {:ok, res} <- query(pair.address, limit),
         {:ok, book} <- new(pair.address, res) do
      {:ok, %{pair | book: book}}
    else
      {:error, err} ->
        Logger.error(__MODULE__, "load #{pair.address} #{inspect(err)}")
        {:ok, %{pair | book: %__MODULE__{id: pair.address}}}
    end
  end

  @spec from_id(String.t()) :: {:ok, t()} | {:error, term()}
  def from_id(id) do
    with {:ok, res} <- Pair.get(id),
         {:ok, %{book: book}} <- load(res, 100) do
      {:ok, book}
    end
  end

  @spec price(String.t()) :: {:ok, map()} | {:error, term()}
  def price(id) do
    with {:ok, book} <- from_id(id) do
      {:ok, %{price: book.center, change: 0}}
    end
  end

  # --- Calculations ---

  @spec populate(t()) :: t()
  defp populate(%__MODULE__{asks: [ask | _], bids: [bid | _]} = book) do
    center =
      ask.price
      |> Decimal.add(bid.price)
      |> Decimal.div(Decimal.new(2))

    %{
      book
      | center: center,
        spread: ask.price |> Decimal.sub(bid.price) |> Decimal.div(center)
    }
  end

  defp populate(book), do: book

  @spec depth(t(), :bid | :ask, number()) :: non_neg_integer()
  def depth(%__MODULE__{bids: []}, :bid, _), do: 0
  def depth(%__MODULE__{asks: []}, :ask, _), do: 0

  def depth(%__MODULE__{bids: [best | _] = bids}, :bid, deviation),
    do: sum_depth(bids, best.price, Decimal.sub(1, Decimal.from_float(deviation)), :lt, :total)

  def depth(%__MODULE__{asks: [best | _] = asks}, :ask, deviation),
    do: sum_depth(asks, best.price, Decimal.add(1, Decimal.from_float(deviation)), :gt, :value)

  defp sum_depth(prices, best, factor, exclude, field) do
    bound = Decimal.mult(best, factor)

    prices
    |> Enum.filter(&(Decimal.compare(&1.price, bound) != exclude))
    |> Enum.reduce(Decimal.new(0), fn p, acc -> Decimal.add(Map.get(p, field), acc) end)
    |> Decimal.round(0, :floor)
    |> Decimal.to_integer()
  end

  # --- Private ---

  defmemo query(contract, limit \\ 100) do
    Contracts.query_state_smart_with_retry(contract, %{book: %{limit: limit}})
  end
end
