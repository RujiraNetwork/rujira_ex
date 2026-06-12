defmodule Rujira.Fin.Events.RangeClose do
  @moduledoc "A range close event (`wasm-rujira-fin/range.close`)."

  alias Rujira.Amount
  alias Rujira.Math

  defstruct idx: 0, owner: nil, base: 0, quote: 0, fee_base: 0, fee_quote: 0

  @type t :: %__MODULE__{
          idx: non_neg_integer(),
          owner: String.t(),
          base: Amount.t(),
          quote: Amount.t(),
          fee_base: Amount.t(),
          fee_quote: Amount.t()
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
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
         {:ok, quote} <- Amount.new(quote),
         {:ok, fee_base} <- Amount.new(fee_base),
         {:ok, fee_quote} <- Amount.new(fee_quote) do
      {:ok,
       %__MODULE__{
         idx: idx,
         owner: owner,
         base: base,
         quote: quote,
         fee_base: fee_base,
         fee_quote: fee_quote
       }}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
