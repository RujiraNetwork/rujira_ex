defmodule Rujira.Revenue.Events.Run do
  @moduledoc "A Revenue run event (`wasm-rujira-revenue/run`)."

  alias Rujira.Assets
  alias Rujira.Assets.Asset

  defstruct asset: nil

  @type t :: %__MODULE__{asset: Asset.t()}

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"denom" => denom}) do
    with {:ok, asset} <- Assets.from_denom(denom) do
      {:ok, %__MODULE__{asset: asset}}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
