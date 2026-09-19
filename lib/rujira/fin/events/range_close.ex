defmodule Rujira.Fin.Events.RangeClose do
  @moduledoc """
  A range close event (`wasm-rujira-fin/range.close`).

  A fixed range returns its principal plus uncollected `fee_base`/`fee_quote`; a
  dynamic range returns its principal plus its segregated claimable balances.
  """

  alias Rujira.Amount
  alias Rujira.Math

  defmodule Fixed do
    @moduledoc "Closing balances of a fixed-bounds range."

    alias Rujira.Amount

    defstruct base: 0, quote: 0, fee_base: 0, fee_quote: 0

    @type t :: %__MODULE__{
            base: Amount.t(),
            quote: Amount.t(),
            fee_base: Amount.t(),
            fee_quote: Amount.t()
          }
  end

  defmodule Dynamic do
    @moduledoc """
    Closing balances of a dynamic range.

    Unlike `Rujira.Fin.Events.RangeClaim.Dynamic`, the contract floors the
    claimable balances here, so these are `Amount.t()` rather than `Decimal.t()`.
    """

    alias Rujira.Amount

    defstruct base: 0, quote: 0, claimable_base: 0, claimable_quote: 0

    @type t :: %__MODULE__{
            base: Amount.t(),
            quote: Amount.t(),
            claimable_base: Amount.t(),
            claimable_quote: Amount.t()
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
        "base" => base,
        "quote" => quote,
        "fee_base" => fee_base,
        "fee_quote" => fee_quote
      }) do
    with {:ok, idx} <- Math.to_integer(idx),
         {:ok, base} <- Amount.new(base),
         {:ok, quote_} <- Amount.new(quote),
         {:ok, fee_base} <- Amount.new(fee_base),
         {:ok, fee_quote} <- Amount.new(fee_quote) do
      {:ok,
       %__MODULE__{
         idx: idx,
         owner: owner,
         range: %Fixed{
           base: base,
           quote: quote_,
           fee_base: fee_base,
           fee_quote: fee_quote
         }
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
         "claimable_base" => claimable_base,
         "claimable_quote" => claimable_quote
       }) do
    with {:ok, idx} <- Math.to_integer(idx),
         {:ok, base} <- Amount.new(base),
         {:ok, quote_} <- Amount.new(quote),
         {:ok, claimable_base} <- Amount.new(claimable_base),
         {:ok, claimable_quote} <- Amount.new(claimable_quote) do
      {:ok,
       %__MODULE__{
         idx: idx,
         owner: owner,
         range: %Dynamic{
           base: base,
           quote: quote_,
           claimable_base: claimable_base,
           claimable_quote: claimable_quote
         }
       }}
    end
  end

  defp new_dynamic(_), do: {:error, :invalid_attrs}
end
