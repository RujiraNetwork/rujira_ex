defmodule Rujira.Ghost.Credit.LiquidateMsg.Repay do
  @moduledoc """
  A liquidation step that repays the whole account balance of one asset
  (`LiquidateMsg::Repay`).
  """

  alias Rujira.Assets
  alias Rujira.Assets.Asset

  # --- Struct ---

  defstruct asset: nil

  @type t :: %__MODULE__{asset: Asset.t() | nil}

  # --- Construction ---

  @doc "Builds the step from the variant's denom - it carries nothing else."
  @spec new(String.t()) :: {:ok, t()} | {:error, term()}
  def new(denom) when is_binary(denom) do
    with {:ok, asset} <- Assets.from_denom(denom) do
      {:ok, %__MODULE__{asset: asset}}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
