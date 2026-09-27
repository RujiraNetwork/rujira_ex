defmodule Rujira.Fin.Book do
  @moduledoc """
  Order book for the FIN protocol.

  Struct, construction, and queries. Use `Rujira.Fin` as the public API.
  """

  alias Rujira.Contracts
  alias Rujira.Fin.Pair
  alias Rujira.Math
  alias Rujira.Node

  use Memoize

  @max_limit 255

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
            center: nil,
            spread: nil

  @type t :: %__MODULE__{
          id: String.t(),
          bids: list(Price.t()),
          asks: list(Price.t()),
          center: Decimal.t() | nil,
          spread: Decimal.t() | nil
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

  @doc """
  Reads a pair's book and attaches it under `book:`.

  `limit` caps how many levels each side keeps; `nil` keeps every level the
  contract returned. A book that cannot be read is an error, never an empty book.
  """
  @spec load(Pair.t(), non_neg_integer() | nil, Node.opts()) ::
          {:ok, Pair.t()} | {:error, term()}
  def load(pair, limit \\ nil, opts \\ []) do
    with {:ok, res} <- query(pair.address, opts),
         {:ok, book} <- new(pair.address, res) do
      {:ok, %{pair | book: take(book, limit)}}
    end
  end

  @doc """
  Reads the book of the pair an `id` names, by that address alone.

  The pair's own config is not read, since a book is built from the book query.
  """
  @spec from_id(String.t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def from_id(id, opts \\ []) do
    with {:ok, res} <- query(id, opts) do
      new(id, res)
    end
  end

  # --- Calculations ---

  # A mid-price needs a level on both sides. With one side empty there is no
  # centre and no spread, so both stay `nil` - an absent value, not a zero.
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

  @spec take(t(), non_neg_integer() | nil) :: t()
  defp take(book, nil), do: book

  defp take(%__MODULE__{bids: bids, asks: asks} = book, limit) do
    %{book | bids: Enum.take(bids, limit), asks: Enum.take(asks, limit)}
  end

  @doc """
  Memoized fetch of a contract's raw order book.

  Invalidate with `Memoize.invalidate(Rujira.Fin.Book, :query, [contract])`.
  """
  @spec query(String.t()) :: {:ok, map() | nil} | {:error, term()}
  defmemo query(contract) do
    fetch(contract, [])
  end

  @doc """
  As `query/1`, read at `opts[:height]` when one is given - a height read is
  never cached. Without a `:height` this is `query/1`, so the other opts are not
  applied.
  """
  @spec query(String.t(), Node.opts()) :: {:ok, map() | nil} | {:error, term()}
  def query(contract, opts) do
    Node.at_height(opts, fn -> fetch(contract, opts) end, fn -> query(contract) end)
  end

  defp fetch(contract, opts) do
    Contracts.query_state_smart_with_retry(contract, %{book: %{limit: @max_limit}}, opts)
  end
end
