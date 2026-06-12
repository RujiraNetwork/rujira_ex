defmodule Rujira.Fin.Events.Arb do
  @moduledoc "An arbitrage capture event (`wasm-rujira-fin/arb`)."

  alias Rujira.Amount

  defstruct base: 0, quote: 0

  @type t :: %__MODULE__{
          base: Amount.t(),
          quote: Amount.t()
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"base" => base, "quote" => quote}) do
    with {:ok, base} <- Amount.new(base),
         {:ok, quote} <- Amount.new(quote) do
      {:ok, %__MODULE__{base: base, quote: quote}}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
