defmodule Rujira.Fin.Events.Price do
  @moduledoc """
  A FIN price, as carried on order and trade events.

  The contract serialises prices as `"<tag>:<value>"`. The tag selects the
  source variant:

    * `fixed:<decimal>`   — an order-pool limit price
    * `oracle:<int>`      — an order-pool oracle deviation, in bps
    * `ccl:<decimal>`     — a concentrated-liquidity (range) effective rate
    * `<address>:<rate>`  — a market-maker offer, prefixed by its contract address
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

  @spec parse(String.t()) :: {:ok, t()} | {:error, term()}
  def parse(value) when is_binary(value) do
    case String.split(value, ":", parts: 2) do
      ["fixed", rest] ->
        with {:ok, value} <- Math.to_decimal(rest), do: {:ok, %Fixed{value: value}}

      ["oracle", rest] ->
        with {:ok, deviation} <- Math.to_integer(rest), do: {:ok, %Oracle{deviation: deviation}}

      ["ccl", rest] ->
        with {:ok, rate} <- Math.to_decimal(rest), do: {:ok, %Ccl{rate: rate}}

      [address, rest] ->
        with {:ok, rate} <- Math.to_decimal(rest),
             do: {:ok, %MarketMaker{address: address, rate: rate}}

      _ ->
        {:error, :invalid_price}
    end
  end

  def parse(_), do: {:error, :invalid_price}
end
