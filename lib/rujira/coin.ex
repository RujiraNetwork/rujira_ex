defmodule Rujira.Coin do
  @moduledoc """
  Canonical coin type for Rujira.

  Represents an asset + amount pair. Amount is always an integer
  in smallest units. Asset is always resolved at construction time.
  """

  alias Rujira.Amount
  alias Rujira.Assets
  alias Rujira.Assets.Asset

  defstruct asset: nil, amount: 0

  @type t :: %__MODULE__{
          asset: Asset.t(),
          amount: Amount.t()
        }

  @doc """
  The native bank denom for this coin's asset.

  Propagates `Rujira.Assets.to_native/1`, so a coin of an asset that has no bank
  denom — a layer-1 asset on another chain, a synth, a trade asset — returns
  `{:error, :no_native_denom}`.
  """
  @spec denom(t()) :: {:ok, String.t()} | {:error, term()}
  def denom(%__MODULE__{asset: asset}), do: Assets.to_native(asset)

  @coin_regex ~r/^(\d+)\s*([a-zA-Z][a-zA-Z0-9\/:._-]{2,127})$/

  @spec new(Asset.t(), non_neg_integer()) :: t()
  def new(%Asset{} = asset, amount) when is_integer(amount) do
    %__MODULE__{asset: asset, amount: amount}
  end

  @spec new(String.t(), non_neg_integer()) :: {:ok, t()} | {:error, term()}
  def new(denom, amount) when is_binary(denom) and is_integer(amount) do
    with {:ok, asset} <- Assets.from_denom(denom) do
      {:ok, new(asset, amount)}
    end
  end

  @spec new(String.t(), String.t()) :: {:ok, t()} | {:error, term()}
  def new(denom, amount) when is_binary(denom) and is_binary(amount) do
    with {:ok, parsed} <- Amount.new(amount) do
      new(denom, parsed)
    end
  end

  @spec new(%{denom: String.t(), amount: String.t()}) :: {:ok, t()} | {:error, term()}
  def new(%{denom: denom, amount: amount}), do: new(denom, amount)

  @doc """
  Parse a comma-separated coin string into a list of coins.
  Supports both `"1000rune"` and `"1000 rune"` formats.
  """
  @spec parse(String.t()) :: {:ok, [t()]} | {:error, :invalid_coin_format}
  def parse(str) when is_binary(str), do: parse_coins(str, &parse_one/1)

  defp parse_one(str) do
    trimmed = String.trim(str)

    case String.split(trimmed, " ", parts: 2) do
      [amount_str, denom] when denom != "" -> build(denom, amount_str)
      _ -> parse_unspaced(trimmed)
    end
  end

  defp parse_unspaced(trimmed) do
    case Regex.run(@coin_regex, trimmed) do
      [_, amount_str, denom] -> build(denom, amount_str)
      _ -> {:error, :invalid_coin_format}
    end
  end

  defp build(denom, amount_str) do
    case Amount.new(amount_str) do
      {:ok, amount} -> new(denom, amount)
      _ -> {:error, :invalid_amount}
    end
  end

  @doc """
  Parse a comma-separated THORChain asset-amount string into a list of coins.

  Supports `"<amount> <ASSET.ID>"` pairs (e.g. `"100000000 BTC.BTC"`,
  `"1 THOR.RUNE"`), where the identifier is a THORChain asset id resolved via
  `Rujira.Assets.from_string/1`, not a bank denom. Use `parse/1` for coin
  strings that carry denoms instead.
  """
  @spec from_asset_string(String.t()) :: {:ok, [t()]} | {:error, :invalid_coin_format}
  def from_asset_string(str) when is_binary(str), do: parse_coins(str, &parse_asset_one/1)

  defp parse_coins(str, build_fn) do
    str
    |> String.split(",", trim: true)
    |> Enum.reduce_while({:ok, []}, fn part, {:ok, acc} ->
      case build_fn.(part) do
        {:ok, coin} -> {:cont, {:ok, [coin | acc]}}
        {:error, _} -> {:halt, {:error, :invalid_coin_format}}
      end
    end)
    |> case do
      {:ok, coins} -> {:ok, Enum.reverse(coins)}
      error -> error
    end
  end

  defp parse_asset_one(str) do
    case String.split(String.trim(str), " ", parts: 2) do
      [amount_str, id] when id != "" -> build_asset(id, amount_str)
      _ -> {:error, :invalid_coin_format}
    end
  end

  defp build_asset(id, amount_str) do
    case Amount.new(amount_str) do
      {:ok, amount} ->
        case Assets.from_id(id) do
          {:ok, asset} -> {:ok, new(asset, amount)}
          {:error, _} -> {:error, :invalid_coin_format}
        end

      _ ->
        {:error, :invalid_amount}
    end
  end
end
