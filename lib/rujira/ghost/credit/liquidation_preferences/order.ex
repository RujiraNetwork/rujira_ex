defmodule Rujira.Ghost.Credit.LiquidationPreferences.Order do
  @moduledoc """
  The order constraints of an account's liquidation preferences.

  Each entry reads "liquidating `asset` is invalid while the account still holds
  `after`". `limit` is the contract's own cap on how many entries it will store.
  """

  alias Rujira.Assets
  alias Rujira.Math

  defmodule Entry do
    @moduledoc "One ordering constraint: `asset` may only be liquidated once `after` is gone."

    alias Rujira.Assets.Asset

    defstruct asset: nil, after: nil

    @type t :: %__MODULE__{asset: Asset.t() | nil, after: Asset.t() | nil}
  end

  # --- Struct ---

  defstruct entries: [], limit: 0

  @type t :: %__MODULE__{entries: [Entry.t()], limit: non_neg_integer()}

  # --- Construction ---

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"map" => map, "limit" => limit}) when is_map(map) do
    with {:ok, entries} <- entries(map),
         {:ok, limit} <- Math.to_integer(limit) do
      {:ok, %__MODULE__{entries: entries, limit: limit}}
    end
  end

  def new(_), do: {:error, :invalid_attrs}

  # --- Private ---

  # A `BTreeMap<denom, denom>` on the wire - keyed by denom, so sorted by denom
  # here too rather than left to map iteration order.
  defp entries(map) do
    map
    |> Enum.sort_by(&elem(&1, 0))
    |> Rujira.Enum.reduce_while_ok([], &entry/1)
  end

  defp entry({denom, after_denom}) when is_binary(denom) and is_binary(after_denom) do
    with {:ok, asset} <- Assets.from_denom(denom),
         {:ok, after_asset} <- Assets.from_denom(after_denom) do
      {:ok, %Entry{asset: asset, after: after_asset}}
    end
  end

  defp entry({_denom, _after_denom}), do: {:error, :invalid_denom}
end
