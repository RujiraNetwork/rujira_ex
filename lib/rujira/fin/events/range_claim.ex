defmodule Rujira.Fin.Events.RangeClaim do
  @moduledoc """
  A range claim event (`wasm-rujira-fin/range.claim`).

  A dynamic range also reports the oracle used to value the claim and the
  claimable balances left behind.
  """

  alias Rujira.Amount
  alias Rujira.Math

  defmodule Fixed do
    @moduledoc "Amounts paid out by a fixed-bounds range claim."

    alias Rujira.Amount

    defstruct base: 0, quote: 0

    @type t :: %__MODULE__{base: Amount.t(), quote: Amount.t()}
  end

  defmodule Dynamic do
    @moduledoc """
    Amounts paid out by a dynamic range claim, and the balances left behind.

    `oracle` and `quote_value` are `nil` when no oracle was available at claim
    time — the contract emits those attributes as empty strings.

    `claimable_base`/`claimable_quote` are the contract's full-precision
    remaining balances, not floored token amounts. The same attributes on
    `Rujira.Fin.Events.RangeClose.Dynamic` *are* floored, hence the differing types.
    """

    alias Rujira.Amount

    defstruct base: 0,
              quote: 0,
              oracle: nil,
              quote_value: nil,
              claimable_base: Decimal.new(0),
              claimable_quote: Decimal.new(0)

    @type t :: %__MODULE__{
            base: Amount.t(),
            quote: Amount.t(),
            oracle: Decimal.t() | nil,
            quote_value: Decimal.t() | nil,
            claimable_base: Decimal.t(),
            claimable_quote: Decimal.t()
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

  def new(%{"idx" => idx, "owner" => owner, "base" => base, "quote" => quote}) do
    with {:ok, idx} <- Math.to_integer(idx),
         {:ok, base} <- Amount.new(base),
         {:ok, quote_} <- Amount.new(quote) do
      {:ok, %__MODULE__{idx: idx, owner: owner, range: %Fixed{base: base, quote: quote_}}}
    end
  end

  def new(_), do: {:error, :invalid_attrs}

  # --- Private ---

  defp new_dynamic(%{
         "idx" => idx,
         "owner" => owner,
         "base" => base,
         "quote" => quote,
         "oracle" => oracle,
         "quote_value" => quote_value,
         "claimable_base" => claimable_base,
         "claimable_quote" => claimable_quote
       }) do
    with {:ok, idx} <- Math.to_integer(idx),
         {:ok, base} <- Amount.new(base),
         {:ok, quote_} <- Amount.new(quote),
         {:ok, oracle} <- Math.to_decimal(blank(oracle)),
         {:ok, quote_value} <- Math.to_decimal(blank(quote_value)),
         {:ok, claimable_base} <- Math.to_decimal(claimable_base),
         {:ok, claimable_quote} <- Math.to_decimal(claimable_quote) do
      {:ok,
       %__MODULE__{
         idx: idx,
         owner: owner,
         range: %Dynamic{
           base: base,
           quote: quote_,
           oracle: oracle,
           quote_value: quote_value,
           claimable_base: claimable_base,
           claimable_quote: claimable_quote
         }
       }}
    end
  end

  defp new_dynamic(_), do: {:error, :invalid_attrs}

  # The contract emits an absent oracle as an empty attribute value.
  defp blank(""), do: nil
  defp blank(value), do: value
end
