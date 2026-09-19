defmodule Rujira.Fin.Events.RangeTransfer do
  @moduledoc """
  A range ownership transfer event (`wasm-rujira-fin/range.transfer`).

  Both implementations carry the same payload, so the nested variants are
  markers — they exist so that matching on `range:` is the one idiom for telling
  the two kinds of range apart across every FIN event.
  """

  alias Rujira.Math

  defmodule Fixed do
    @moduledoc "Marks the transfer as being of a fixed-bounds range."

    defstruct []

    @type t :: %__MODULE__{}
  end

  defmodule Dynamic do
    @moduledoc "Marks the transfer as being of a dynamic range."

    defstruct []

    @type t :: %__MODULE__{}
  end

  defstruct idx: 0, from: nil, to: nil, range: nil

  @type t :: %__MODULE__{
          idx: non_neg_integer(),
          from: String.t(),
          to: String.t(),
          range: Fixed.t() | Dynamic.t() | nil
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()} | :pass
  def new(%{"range_type" => "dynamic"} = attrs), do: new_dynamic(attrs)
  def new(%{"range_type" => _}), do: :pass

  def new(%{"idx" => idx, "from" => from, "to" => to}) do
    with {:ok, idx} <- Math.to_integer(idx) do
      {:ok, %__MODULE__{idx: idx, from: from, to: to, range: %Fixed{}}}
    end
  end

  def new(_), do: {:error, :invalid_attrs}

  # --- Private ---

  defp new_dynamic(%{"idx" => idx, "from" => from, "to" => to}) do
    with {:ok, idx} <- Math.to_integer(idx) do
      {:ok, %__MODULE__{idx: idx, from: from, to: to, range: %Dynamic{}}}
    end
  end

  defp new_dynamic(_), do: {:error, :invalid_attrs}
end
