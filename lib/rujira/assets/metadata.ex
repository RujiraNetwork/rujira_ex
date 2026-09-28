defmodule Rujira.Assets.Metadata do
  @moduledoc """
  Module for handling asset metadata.

  Denom metadata (symbol, name, display) is token identity, not chain state -
  it is always read at latest and memoized, even for a caller passing
  `:height`. See "Tokens" in `guides/conventions.md`.
  """

  alias Cosmos.Bank.V1beta1.Metadata, as: DenomMetadata
  alias Cosmos.Bank.V1beta1.Query.Stub
  alias Cosmos.Bank.V1beta1.QueryDenomMetadataRequest
  alias Cosmos.Bank.V1beta1.QueryDenomMetadataResponse
  alias Rujira.Node

  use Memoize

  defstruct decimals: nil,
            description: nil,
            display: nil,
            name: nil,
            symbol: nil,
            uri: nil,
            uri_hash: nil,
            png_url: nil,
            svg_url: nil

  @type t :: %__MODULE__{
          decimals: non_neg_integer() | nil,
          description: String.t(),
          display: String.t(),
          name: String.t(),
          symbol: String.t(),
          uri: String.t(),
          uri_hash: String.t(),
          png_url: String.t(),
          svg_url: String.t()
        }

  @doc """
  Denom metadata. `decimals` is read from the metadata's `denom_units`: the
  exponent of the unit the chain names as its `display`, or - when that unit is
  the base unit (exponent `0`) or is absent - the largest exponent declared. A
  denom whose metadata declares no unit at all has no decimals, so `decimals`
  is `nil`.

  A denom's metadata is set when the denom is created and does
  not change afterwards, so a successful node response is memoized (privately,
  as `do_load_metadata/1`) without expiry. A failed query returns the node's
  error unchanged and is not memoized, so a later call retries it.

  Invalidate with
  `Memoize.invalidate(Rujira.Assets.Metadata, :do_load_metadata, [denom])`.

  Denom metadata is token identity, not chain state (see `guides/conventions.md`),
  so it is always read at latest and memoized - `opts` is accepted for arity
  parity with the rest of the node-reading API, but a `:height` in it is
  ignored. The one consequence: an admin metadata change shows the current
  symbol even in a historical read.
  """
  @spec load_metadata(String.t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def load_metadata(denom, _opts \\ []) do
    cached_metadata(denom)
  end

  # --- Private ---

  defmemop(do_load_metadata(denom), do: fetch_metadata(denom))

  defp cached_metadata(denom) do
    case do_load_metadata(denom) do
      {:ok, metadata} ->
        {:ok, metadata}

      {:error, reason} ->
        Memoize.invalidate(__MODULE__, :do_load_metadata, [denom])
        {:error, reason}
    end
  end

  defp fetch_metadata(denom) do
    q = %QueryDenomMetadataRequest{denom: denom}

    case Node.query(&Stub.denom_metadata/3, q) do
      {:ok, %QueryDenomMetadataResponse{metadata: metadata}} ->
        {:ok,
         %__MODULE__{
           decimals: decimals(metadata),
           description: metadata.description,
           display: metadata.display,
           name: metadata.name,
           symbol: metadata.symbol,
           uri: metadata.uri,
           uri_hash: metadata.uri_hash
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # The display unit carries the token's decimals, but a denom whose `display`
  # is its own base unit declares that exponent as `0` - the largest exponent is
  # the token's own then.
  defp decimals(%DenomMetadata{display: display, denom_units: denom_units}) do
    case Enum.find(denom_units, &(&1.denom == display)) do
      %{exponent: exponent} when exponent > 0 -> exponent
      _ -> largest_exponent(denom_units)
    end
  end

  defp largest_exponent([]), do: nil
  defp largest_exponent(denom_units), do: denom_units |> Enum.map(& &1.exponent) |> Enum.max()
end
