defmodule Rujira.Fin.Events.RangeClaim do
  @moduledoc "A range claim event (`wasm-rujira-fin/range.claim`)."

  alias Rujira.Amount
  alias Rujira.Math

  defstruct idx: 0, owner: nil, base: 0, quote: 0

  @type t :: %__MODULE__{
          idx: non_neg_integer(),
          owner: String.t(),
          base: Amount.t(),
          quote: Amount.t()
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"idx" => idx, "owner" => owner, "base" => base, "quote" => quote}) do
    with {:ok, idx} <- Math.to_integer(idx),
         {:ok, base} <- Amount.new(base),
         {:ok, quote} <- Amount.new(quote) do
      {:ok, %__MODULE__{idx: idx, owner: owner, base: base, quote: quote}}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
