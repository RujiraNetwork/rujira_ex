defmodule Rujira.Assets.Metadata do
  @moduledoc """
  Module for handling asset metadata.

  Denom metadata (symbol, name, display) is token identity, not chain state -
  it is always read at latest, even for a caller passing `:height`, and cached
  per `Rujira.Cache` as an identity fact. See "Tokens" in
  `guides/conventions.md`.

  The node holding *no* metadata for a denom is not identity: it stops being
  true the moment the denom is created. It is cached against
  `{:denom_metadata, denom}` instead, which `Rujira.Cache.Invalidator` raises
  on the `create_denom` event.
  """

  alias Cosmos.Bank.V1beta1.Metadata, as: DenomMetadata
  alias Cosmos.Bank.V1beta1.Query.Stub
  alias Cosmos.Bank.V1beta1.QueryDenomMetadataRequest
  alias Cosmos.Bank.V1beta1.QueryDenomMetadataResponse
  alias GRPC.RPCError
  alias Rujira.Cache
  alias Rujira.Node

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

  A denom's metadata is set when the denom is created and no message can
  change it afterwards, so it is cached per `Rujira.Cache` as an identity
  fact, forever.

  The node answering that it holds none - `{:error, :not_found}` here - is a
  fact too, but only until a block creates the denom, so it is cached against
  `{:denom_metadata, denom}` and refetched by the first `advance/1` that
  applies a `create_denom` for it. Before the first `advance/1` there is no
  head to anchor that fact to, and it is simply not cached; the lookup still
  works. A failed query returns the node's error unchanged and is never
  cached, so a later call retries it.

  Denom metadata is token identity, not chain state (see `guides/conventions.md`),
  so it is always read at latest - `opts` is accepted for arity parity with the
  rest of the node-reading API, but a `:height` in it is ignored. Nothing is
  lost by that today: metadata that exists cannot change, and a denom the
  node's latest does not know was not created at or before the head either.
  """
  @spec load_metadata(String.t(), Node.opts()) ::
          {:ok, t()} | {:error, :not_found} | {:error, term()}
  def load_metadata(denom, opts \\ []) do
    Cache.fetch({__MODULE__, :load_metadata, [denom]}, :identity, opts, fn _height ->
      read(denom)
    end)
  end

  # --- Private ---

  # Two facts with two lifetimes, out of one node read.
  #
  # Metadata the node holds can never change, so it is this function's own
  # result and lands in the identity store above. The node holding none lasts
  # only until a block creates the denom, so `absence/1` caches it under its
  # own key - and hands metadata back as `{:present, _}`, an error, so that the
  # absence cache stores nothing for a denom that does exist.
  defp read(denom) do
    case absence(denom) do
      {:ok, :none} -> {:error, :not_found}
      {:error, {:present, metadata}} -> {:ok, metadata}
      {:error, reason} -> {:error, reason}
    end
  end

  # The absence is anchored at the head, never at the caller's `:height`: the
  # read is at the node's latest, and creation is monotonic, so a denom latest
  # does not know was not created at or before the head either. With no head -
  # `advance/1` never called - there is nothing to anchor it to, and metadata
  # lookups must keep working without one, so the read goes straight through.
  defp absence(denom) do
    case Cache.head() do
      nil -> fetch_metadata(denom)
      _head -> cached_absence(denom)
    end
  end

  defp cached_absence(denom) do
    Cache.fetch({__MODULE__, :absence, [denom]}, [{:denom_metadata, denom}], [], fn _height ->
      fetch_metadata(denom)
    end)
  end

  defp fetch_metadata(denom) do
    q = %QueryDenomMetadataRequest{denom: denom}

    case Node.query(&Stub.denom_metadata/3, q) do
      {:ok, %QueryDenomMetadataResponse{metadata: metadata}} ->
        {:error, {:present, new(metadata)}}

      {:error, %RPCError{status: 5, message: "client metadata for denom" <> _}} ->
        {:ok, :none}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp new(metadata) do
    %__MODULE__{
      decimals: decimals(metadata),
      description: metadata.description,
      display: metadata.display,
      name: metadata.name,
      symbol: metadata.symbol,
      uri: metadata.uri,
      uri_hash: metadata.uri_hash
    }
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
