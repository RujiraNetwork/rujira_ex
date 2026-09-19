defmodule Rujira.Fin.Events.RangeCreate do
  @moduledoc """
  A range creation event (`wasm-rujira-fin/range.create`).

  Both range implementations emit this event. A fixed range carries no
  `range_type` attribute; a dynamic one sets `range_type=dynamic` and replaces
  the price bounds with its strategy parameters.
  """

  alias Rujira.Amount
  alias Rujira.Fin.Range.Dynamic.Params
  alias Rujira.Math

  defmodule Fixed do
    @moduledoc "Creation state of a fixed-bounds range."

    alias Rujira.Amount

    defstruct high: Decimal.new(0),
              low: Decimal.new(0),
              skew: Decimal.new(0),
              spread: Decimal.new(0),
              fee: Decimal.new(0),
              base: 0,
              quote: 0

    @type t :: %__MODULE__{
            high: Decimal.t(),
            low: Decimal.t(),
            skew: Decimal.t(),
            spread: Decimal.t(),
            fee: Decimal.t(),
            base: Amount.t(),
            quote: Amount.t()
          }
  end

  defmodule Dynamic do
    @moduledoc "Creation state of a dynamic range, anchored at `aep`."

    alias Rujira.Amount
    alias Rujira.Fin.Range.Dynamic.Params

    defstruct params: %Params{}, base: 0, quote: 0, aep: Decimal.new(0)

    @type t :: %__MODULE__{
            params: Params.t(),
            base: Amount.t(),
            quote: Amount.t(),
            aep: Decimal.t()
          }
  end

  defstruct idx: 0, owner: nil, range: nil

  @type t :: %__MODULE__{
          idx: non_neg_integer(),
          owner: String.t(),
          range: Fixed.t() | Dynamic.t() | nil
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()} | :pass
  def new(%{"range_type" => "dynamic"} = attrs), do: new_dynamic(attrs)
  def new(%{"range_type" => _}), do: :pass

  def new(%{
        "idx" => idx,
        "owner" => owner,
        "high" => high,
        "low" => low,
        "skew" => skew,
        "spread" => spread,
        "fee" => fee,
        "base" => base,
        "quote" => quote
      }) do
    with {:ok, idx} <- Math.to_integer(idx),
         {:ok, high} <- Math.to_decimal(high),
         {:ok, low} <- Math.to_decimal(low),
         {:ok, skew} <- Math.to_decimal(skew),
         {:ok, spread} <- Math.to_decimal(spread),
         {:ok, fee} <- Math.to_decimal(fee),
         {:ok, base} <- Amount.new(base),
         {:ok, quote_} <- Amount.new(quote) do
      {:ok,
       %__MODULE__{
         idx: idx,
         owner: owner,
         range: %Fixed{
           high: high,
           low: low,
           skew: skew,
           spread: spread,
           fee: fee,
           base: base,
           quote: quote_
         }
       }}
    end
  end

  def new(_), do: {:error, :invalid_attrs}

  # --- Private ---

  defp new_dynamic(
         %{
           "idx" => idx,
           "owner" => owner,
           "base" => base,
           "quote" => quote,
           "aep" => aep
         } = attrs
       ) do
    with {:ok, idx} <- Math.to_integer(idx),
         {:ok, params} <- Params.new(attrs),
         {:ok, base} <- Amount.new(base),
         {:ok, quote_} <- Amount.new(quote),
         {:ok, aep} <- Math.to_decimal(aep) do
      {:ok,
       %__MODULE__{
         idx: idx,
         owner: owner,
         range: %Dynamic{params: params, base: base, quote: quote_, aep: aep}
       }}
    end
  end

  defp new_dynamic(_), do: {:error, :invalid_attrs}
end
