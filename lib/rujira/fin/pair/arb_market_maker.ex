defmodule Rujira.Fin.Pair.ArbMarketMaker do
  @moduledoc """
  One entry of a FIN pair's `arb_market_makers`: an arbitrage provider, and
  which kind it is.

  An embedded value struct of `Rujira.Fin.Pair`, with no address of its own to
  read it from, so it has no `id` or `from_id/2`.

  The contract's `ArbMarketMaker` is externally tagged on the wire:
  `{"endblock": addr}` or `{"standard": addr}`. `:endblock` is an exact-lot
  provider run at end block. `:standard` is obsolete from `dacb42c` - the
  contract rejects it in new configuration - but a stored config may still
  hold one, so it is still read.
  """

  defstruct address: nil, kind: nil

  @type kind :: :endblock | :standard
  @type t :: %__MODULE__{address: String.t() | nil, kind: kind() | nil}

  @spec new(map()) :: {:ok, t()} | {:error, :invalid_attrs}
  def new(%{"endblock" => address} = attrs) when is_binary(address) and map_size(attrs) == 1,
    do: {:ok, %__MODULE__{address: address, kind: :endblock}}

  def new(%{"standard" => address} = attrs) when is_binary(address) and map_size(attrs) == 1,
    do: {:ok, %__MODULE__{address: address, kind: :standard}}

  def new(_), do: {:error, :invalid_attrs}
end
