defmodule Rujira.Fin.Price do
  @moduledoc """
  A FIN price, as carried on order/trade events and in order queries.

  The contract serialises prices as `"<tag>:<value>"`. The tag selects the
  source variant:

    * `fixed:<decimal>`   — an order-pool limit price
    * `oracle:<int>`      — an order-pool oracle deviation, in bps
    * `ccl:<decimal>`     — a concentrated-liquidity (range) effective rate
    * `<address>:<rate>`  — a market-maker offer, prefixed by its contract address

  Orders only ever carry `fixed` or `oracle` prices (`t:order/0`); `ccl` and
  market-maker prices appear on trade events only.

  Decimal values are normalised on construction so equal prices are equal terms.
  This lets a `Price.t()` be used directly as a memoized cache key — the same
  price parsed from an event, an order id, or an order query always compares
  equal, so querying and invalidating share one typed boundary.
  """

  alias Rujira.Math

  defmodule Fixed do
    @moduledoc "A fixed order-pool price (`fixed:<decimal>`)."
    defstruct value: Decimal.new(0)
    @type t :: %__MODULE__{value: Decimal.t()}
  end

  defmodule Oracle do
    @moduledoc "An oracle-relative order-pool price (`oracle:<bps>`)."
    defstruct deviation: 0
    @type t :: %__MODULE__{deviation: integer()}
  end

  defmodule Ccl do
    @moduledoc "A concentrated-liquidity range rate (`ccl:<decimal>`)."
    defstruct rate: Decimal.new(0)
    @type t :: %__MODULE__{rate: Decimal.t()}
  end

  defmodule MarketMaker do
    @moduledoc "A market-maker offer (`<address>:<rate>`)."
    defstruct address: nil, rate: Decimal.new(0)
    @type t :: %__MODULE__{address: String.t(), rate: Decimal.t()}
  end

  @type t :: Fixed.t() | Oracle.t() | Ccl.t() | MarketMaker.t()
  @type order :: Fixed.t() | Oracle.t()

  # --- Parsing ---

  @doc "Parses any price from its `\"<tag>:<value>\"` event form."
  @spec parse(String.t()) :: {:ok, t()} | {:error, term()}
  def parse(value) when is_binary(value) do
    case String.split(value, ":", parts: 2) do
      ["fixed", rest] ->
        with {:ok, value} <- decimal(rest), do: {:ok, %Fixed{value: value}}

      ["oracle", rest] ->
        with {:ok, deviation} <- Math.to_integer(rest), do: {:ok, %Oracle{deviation: deviation}}

      ["ccl", rest] ->
        with {:ok, rate} <- decimal(rest), do: {:ok, %Ccl{rate: rate}}

      [address, rest] ->
        with {:ok, rate} <- decimal(rest),
             do: {:ok, %MarketMaker{address: address, rate: rate}}

      _ ->
        {:error, :invalid_price}
    end
  end

  def parse(_), do: {:error, :invalid_price}

  @doc "Parses an order price (`fixed`/`oracle` only) from its `\"<tag>:<value>\"` id segment."
  @spec parse_order(String.t()) :: {:ok, order()} | {:error, term()}
  def parse_order("fixed:" <> rest) do
    with {:ok, value} <- decimal(rest), do: {:ok, %Fixed{value: value}}
  end

  def parse_order("oracle:" <> rest) do
    with {:ok, deviation} <- Math.to_integer(rest), do: {:ok, %Oracle{deviation: deviation}}
  end

  def parse_order(_), do: {:error, :invalid_price}

  @doc """
  Builds an order price from the map form returned by the contract order query
  (`%{"fixed" => decimal}` or `%{"oracle" => bps}`).
  """
  @spec from_query(map()) :: {:ok, order()} | {:error, term()}
  def from_query(%{"fixed" => value}) do
    with {:ok, value} <- decimal(value), do: {:ok, %Fixed{value: value}}
  end

  def from_query(%{"oracle" => deviation}) do
    with {:ok, deviation} <- Math.to_integer(deviation), do: {:ok, %Oracle{deviation: deviation}}
  end

  def from_query(_), do: {:error, :invalid_price}

  # --- Serialization ---

  @doc "Serialises an order price to the map form expected by the contract order query."
  @spec to_query(order()) :: map()
  def to_query(%Fixed{value: value}), do: %{fixed: Decimal.to_string(value, :normal)}
  def to_query(%Oracle{deviation: deviation}), do: %{oracle: deviation}

  @doc "Serialises an order price to its `\"<tag>:<value>\"` id segment."
  @spec to_id(order()) :: String.t()
  def to_id(%Fixed{value: value}), do: "fixed:#{Decimal.to_string(value, :normal)}"
  def to_id(%Oracle{deviation: deviation}), do: "oracle:#{deviation}"

  # --- Private ---

  @spec decimal(integer() | float() | String.t() | Decimal.t()) ::
          {:ok, Decimal.t()} | {:error, term()}
  defp decimal(value) do
    case Math.to_decimal(value) do
      {:ok, nil} -> {:error, :invalid_decimal}
      {:ok, decimal} -> {:ok, Decimal.normalize(decimal)}
      {:error, _} = err -> err
    end
  end
end
