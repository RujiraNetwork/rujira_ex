defmodule Rujira.Assets.Metadata do
  @moduledoc """
  Module for handling asset metadata.

  Denom metadata (symbol, name, display) is token identity, not chain state -
  it is always read at latest and memoized, even for a caller passing
  `:height`. See "Tokens" in `guides/conventions.md`.
  """

  alias Cosmos.Bank.V1beta1.Query.Stub
  alias Cosmos.Bank.V1beta1.QueryDenomMetadataRequest
  alias Cosmos.Bank.V1beta1.QueryDenomMetadataResponse
  alias Rujira.Node

  use Memoize

  defstruct decimals: 0,
            description: nil,
            display: nil,
            name: nil,
            symbol: nil,
            uri: nil,
            uri_hash: nil,
            png_url: nil,
            svg_url: nil

  @type t :: %__MODULE__{
          decimals: integer(),
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
  Denom metadata. A denom's metadata is set when the denom is created and does
  not change afterwards, so a successful node response is memoized (privately,
  as `do_load_metadata/1`) without expiry. A failed query returns the fallback
  below but is not memoized, so a later call retries it.

  Invalidate with
  `Memoize.invalidate(Rujira.Assets.Metadata, :do_load_metadata, [denom])`.

  Denom metadata is token identity, not chain state (see `guides/conventions.md`),
  so it is always read at latest and memoized - `opts` is accepted for arity
  parity with the rest of the node-reading API, but a `:height` in it is
  ignored. The one consequence: an admin metadata change shows the current
  symbol even in a historical read.
  """
  @spec load_metadata(String.t(), Node.opts()) :: {:ok, t()}
  def load_metadata(denom, _opts \\ []) do
    cached_metadata(denom)
  end

  # --- Private ---

  defmemop(do_load_metadata(denom), do: fetch_metadata(denom))

  defp cached_metadata(denom) do
    case do_load_metadata(denom) do
      {:ok, metadata} ->
        {:ok, metadata}

      :error ->
        Memoize.invalidate(__MODULE__, :do_load_metadata, [denom])
        fallback(denom)
    end
  end

  defp fallback(denom) do
    {:ok,
     %__MODULE__{
       description: "",
       display: String.upcase(denom),
       name: String.upcase(denom),
       symbol: denom,
       uri: "",
       uri_hash: ""
     }}
  end

  defp fetch_metadata(denom) do
    q = %QueryDenomMetadataRequest{denom: denom}

    case Node.query(&Stub.denom_metadata/3, q) do
      {:ok, %QueryDenomMetadataResponse{metadata: metadata}} ->
        {:ok,
         %__MODULE__{
           description: metadata.description,
           display: metadata.display,
           name: metadata.name,
           symbol: metadata.symbol,
           uri: metadata.uri,
           uri_hash: metadata.uri_hash
         }}

      _ ->
        :error
    end
  end
end
