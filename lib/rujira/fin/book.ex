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
    alias Rujira.Math

    defstruct [:price, :total, :side, :value, :virtual_total, :virtual_value]

    @type side :: :bid | :ask
    @type t :: %__MODULE__{
            price: Decimal.t(),
            total: non_neg_integer(),
            side: side,
            value: non_neg_integer(),
            virtual_total: non_neg_integer(),
            virtual_value: non_neg_integer()
          }

    @spec new(side, map()) :: {:ok, t()} | {:error, :parse_error}
    def new(side, %{"price" => price_str, "total" => total_str}) do
      with {:ok, price} <- Math.to_decimal(price_str),
           {:ok, total} <- Math.to_integer(total_str) do
        {:ok,
         %__MODULE__{
           side: side,
           total: total,
           price: price,
           value: value(side, price, total),
           virtual_total: 0,
           virtual_value: 0
         }}
      else
        _ -> {:error, :parse_error}
      end
    end

    @spec value(side, Decimal.t(), non_neg_integer()) :: non_neg_integer()
    def value(:ask, price, total) do
      total
      |> Decimal.new()
      |> Decimal.mult(price)
      |> Decimal.round(0, :floor)
      |> Decimal.to_integer()
    end

    def value(:bid, price, total) do
      total
      |> Decimal.new()
      |> Decimal.div(price)
      |> Decimal.round(0, :floor)
      |> Decimal.to_integer()
    end
  end

  defstruct [:id, :bids, :asks, :center, :spread]

  @type t :: %__MODULE__{
          id: String.t(),
          bids: list(Price.t()),
          asks: list(Price.t()),
          center: Decimal.t(),
          spread: Decimal.t()
        }

  # --- Construction ---

  @spec new(String.t(), map()) :: {:ok, t()}
  def new(address, %{"base" => asks, "quote" => bids}) do
    {:ok,
     %__MODULE__{
       id: address,
       asks: asks |> Enum.map(&Price.new(:ask, &1)) |> filter_ok(),
       bids: bids |> Enum.map(&Price.new(:bid, &1)) |> filter_ok(),
       center: Decimal.new(0),
       spread: Decimal.new(0)
     }
     |> populate()}
  end

  @spec empty(String.t()) :: t()
  def empty(address) do
    %__MODULE__{
      id: address,
      bids: [],
      asks: [],
      center: Decimal.new(0),
      spread: Decimal.new(0)
    }
  end

  # --- Queries ---

  @spec load(Pair.t(), integer()) :: {:ok, Pair.t()} | {:error, term()}
  def load(pair, limit \\ 75)

  def load(%{deployment_status: :preview} = pair, _limit) do
    {:ok, %{pair | book: empty(pair.address)}}
  end

  def load(pair, limit) do
    with {:ok, res} <- query(pair.address, limit),
         {:ok, book} <- new(pair.address, res) do
      {:ok, %{pair | book: book}}
    else
      {:error, err} ->
        Logger.error(__MODULE__, "load #{pair.address} #{inspect(err)}")
        {:ok, %{pair | book: empty(pair.address)}}
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
  def populate(%__MODULE__{asks: [ask | _], bids: [bid | _]} = book) do
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

  def populate(book), do: book

  @spec depth(t(), :bid | :ask, number()) :: non_neg_integer()
  def depth(%__MODULE__{bids: []}, :bid, _), do: 0
  def depth(%__MODULE__{asks: []}, :ask, _), do: 0

  def depth(%__MODULE__{bids: [best | _] = bids}, :bid, deviation) do
    deviation = Decimal.from_float(deviation)
    lower_bound = Decimal.mult(best.price, Decimal.sub(1, deviation))

    bids
    |> Enum.filter(&(Decimal.compare(&1.price, lower_bound) != :lt))
    |> Enum.reduce(Decimal.new(0), fn bid, acc -> Decimal.add(bid.total, acc) end)
    |> Decimal.round(0, :floor)
    |> Decimal.to_integer()
  end

  def depth(%__MODULE__{asks: [best | _] = asks}, :ask, deviation) do
    deviation = Decimal.from_float(deviation)
    upper_bound = Decimal.mult(best.price, Decimal.add(1, deviation))

    asks
    |> Enum.filter(&(Decimal.compare(&1.price, upper_bound) != :gt))
    |> Enum.reduce(Decimal.new(0), fn ask, acc -> Decimal.add(ask.value, acc) end)
    |> Decimal.round(0, :floor)
    |> Decimal.to_integer()
  end

  # --- Private ---

  defmemo query(contract, limit \\ 100) do
    Contracts.query_state_smart_with_retry(contract, %{book: %{limit: limit}})
  end

  @spec filter_ok([{:ok, Price.t()} | {:error, term()}]) :: [Price.t()]
  defp filter_ok(results) do
    for {:ok, price} <- results, do: price
  end
end
