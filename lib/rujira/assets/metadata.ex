defmodule Rujira.Assets.Metadata do
  @moduledoc """
  Module for handling asset metadata.
  """

  alias Cosmos.Bank.V1beta1.Query.Stub
  alias Cosmos.Bank.V1beta1.QueryDenomMetadataRequest
  alias Cosmos.Bank.V1beta1.QueryDenomMetadataResponse

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

  def load_metadata(denom) do
    q = %QueryDenomMetadataRequest{denom: denom}

    case Rujira.Node.query(&Stub.denom_metadata/2, q) do
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
  end
end
