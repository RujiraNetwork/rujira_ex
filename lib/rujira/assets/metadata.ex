defmodule Rujira.Assets.Metadata do
  @moduledoc """
  Module for handling asset metadata.

  Denom metadata (symbol, name, display) is token identity, not chain state -
  it is always read at latest, even for a caller passing `:height`, and cached
  per `Rujira.Cache` as an identity fact. See "Tokens" in
  `guides/conventions.md`.
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

  A denom's metadata is set when the denom is created and does not change
  afterwards, so it is cached per `Rujira.Cache` as an identity fact - and so
  is the node answering that it holds none, which is
  `{:error, :not_found}` here. A failed query returns the node's error
  unchanged and is never cached, so a later call retries it.

  Denom metadata is token identity, not chain state (see `guides/conventions.md`),
  so it is always read at latest - `opts` is accepted for arity parity with the
  rest of the node-reading API, but a `:height` in it is ignored. The one
  consequence: an admin metadata change shows the current symbol even in a
  historical read; `Rujira.Cache.invalidate_all/0` is the lever for it.
  """
  @spec load_metadata(String.t(), Node.opts()) ::
          {:ok, t()} | {:error, :not_found} | {:error, term()}
  def load_metadata(denom, opts \\ []) do
    case Cache.fetch({__MODULE__, :load_metadata, [denom]}, :identity, opts, fn _height ->
           fetch_metadata(denom)
         end) do
      {:ok, :none} -> {:error, :not_found}
      other -> other
    end
  end

  # --- Private ---

  # The node holding no metadata for a denom is a fact about the denom, not a
  # failed read, so it is cached as one.
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

      {:error, %RPCError{status: 5, message: "client metadata for denom" <> _}} ->
        {:ok, :none}

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
