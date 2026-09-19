defmodule Rujira.Fin.Events.RangeWithdraw do
  @moduledoc """
  A range withdrawal event (`wasm-rujira-fin/range.withdraw`).

  A fixed range reports the `amount` of the position withdrawn as a fraction; a
  dynamic range withdraws explicit base/quote amounts instead and reports the
  `aep` it is left anchored at.
  """

  alias Rujira.Amount
  alias Rujira.Math

  defmodule Fixed do
    @moduledoc "Amounts withdrawn from a fixed-bounds range."

    alias Rujira.Amount

    defstruct amount: Decimal.new(0), base: 0, quote: 0

    @type t :: %__MODULE__{amount: Decimal.t(), base: Amount.t(), quote: Amount.t()}
  end

  defmodule Dynamic do
    @moduledoc "Amounts withdrawn from a dynamic range, and its resulting `aep`."

    alias Rujira.Amount

    defstruct base: 0, quote: 0, aep: Decimal.new(0)

    @type t :: %__MODULE__{base: Amount.t(), quote: Amount.t(), aep: Decimal.t()}
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

  def new(%{"idx" => idx, "owner" => owner, "amount" => amount, "base" => base, "quote" => quote}) do
    with {:ok, idx} <- Math.to_integer(idx),
         {:ok, amount} <- Math.to_decimal(amount),
         {:ok, base} <- Amount.new(base),
         {:ok, quote_} <- Amount.new(quote) do
      {:ok,
       %__MODULE__{
         idx: idx,
         owner: owner,
         range: %Fixed{amount: amount, base: base, quote: quote_}
       }}
    end
  end

  def new(_), do: {:error, :invalid_attrs}

  # --- Private ---

  defp new_dynamic(%{
         "idx" => idx,
         "owner" => owner,
         "base" => base,
         "quote" => quote,
         "aep" => aep
       }) do
    with {:ok, idx} <- Math.to_integer(idx),
         {:ok, base} <- Amount.new(base),
         {:ok, quote_} <- Amount.new(quote),
         {:ok, aep} <- Math.to_decimal(aep) do
      {:ok,
       %__MODULE__{
         idx: idx,
         owner: owner,
         range: %Dynamic{base: base, quote: quote_, aep: aep}
       }}
    end
  end

  defp new_dynamic(_), do: {:error, :invalid_attrs}
end
