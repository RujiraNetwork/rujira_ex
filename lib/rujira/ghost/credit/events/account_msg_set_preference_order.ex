defmodule Rujira.Ghost.Credit.Events.AccountMsgSetPreferenceOrder do
  @moduledoc """
  An owner setting one liquidation order constraint
  (`wasm-rujira-ghost-credit/account.msg/set_preference_order`).

  `after` is `nil` when the constraint was removed - the contract emits the
  absent value as `""`.
  """

  alias Rujira.Assets
  alias Rujira.Assets.Asset

  defstruct asset: nil, after: nil

  @type t :: %__MODULE__{asset: Asset.t(), after: Asset.t() | nil}

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"denom" => denom, "after" => after_denom})
      when is_binary(denom) and is_binary(after_denom) do
    with {:ok, asset} <- Assets.from_denom(denom),
         {:ok, after_asset} <- after_asset(after_denom) do
      {:ok, %__MODULE__{asset: asset, after: after_asset}}
    end
  end

  def new(_), do: {:error, :invalid_attrs}

  defp after_asset(""), do: {:ok, nil}
  defp after_asset(denom), do: Assets.from_denom(denom)
end
