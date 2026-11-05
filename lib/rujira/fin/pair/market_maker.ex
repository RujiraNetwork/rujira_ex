defmodule Rujira.Fin.Pair.MarketMaker do
  @moduledoc """
  One entry of a FIN pair's `market_makers`: ordinary user liquidity, and
  whether it may arbitrage before user activity.

  An embedded value struct of `Rujira.Fin.Pair`, with no address of its own to
  read it from, so it has no `id` or `from_id/2`.

  The contract's `MarketMakerConfig` is untagged on the wire. A plain address
  string (every shape before S8) and an `{addr}` object without `arb` both read
  as `arb: false`, the contract's own default.
  """

  defstruct address: nil, arb: false

  @type t :: %__MODULE__{address: String.t(), arb: boolean()}

  @spec new(String.t() | map()) :: {:ok, t()} | {:error, :invalid_attrs}
  def new(address) when is_binary(address), do: {:ok, %__MODULE__{address: address}}

  def new(%{"addr" => address, "arb" => arb}) when is_binary(address) and is_boolean(arb),
    do: {:ok, %__MODULE__{address: address, arb: arb}}

  def new(%{"addr" => address} = attrs) when is_binary(address) and not is_map_key(attrs, "arb"),
    do: {:ok, %__MODULE__{address: address}}

  def new(_), do: {:error, :invalid_attrs}
end
