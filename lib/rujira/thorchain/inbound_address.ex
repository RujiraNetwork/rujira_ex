defmodule Rujira.Thorchain.InboundAddress do
  @moduledoc """
  A chain's inbound (vault) address and gas/fee parameters.

  Struct, construction, and queries. Use `Rujira.Thorchain` as the public API.
  """

  alias Rujira.Amount
  alias Rujira.String
  alias Thorchain.Types.Query.Stub
  alias Thorchain.Types.QueryInboundAddressesRequest
  alias Thorchain.Types.QueryInboundAddressesResponse
  alias Thorchain.Types.QueryInboundAddressResponse

  use Memoize

  # --- Struct ---

  defstruct id: nil,
            chain: nil,
            address: nil,
            halted: false,
            pub_key: nil,
            router: nil,
            gas_rate: 0,
            gas_rate_units: nil,
            outbound_tx_size: 0,
            outbound_fee: 0,
            dust_threshold: 0

  @type t :: %__MODULE__{
          id: String.t() | nil,
          chain: String.t() | nil,
          address: String.t() | nil,
          halted: boolean(),
          pub_key: String.t() | nil,
          router: String.t() | nil,
          gas_rate: Amount.t(),
          gas_rate_units: String.t() | nil,
          outbound_tx_size: Amount.t(),
          outbound_fee: Amount.t(),
          dust_threshold: Amount.t()
        }

  # --- Construction ---

  @spec new(QueryInboundAddressResponse.t()) :: {:ok, t()} | {:error, term()}
  def new(%QueryInboundAddressResponse{} = address) do
    with {:ok, gas_rate} <- Amount.new(address.gas_rate),
         {:ok, outbound_tx_size} <- Amount.new(address.outbound_tx_size),
         {:ok, outbound_fee} <- Amount.new(address.outbound_fee),
         {:ok, dust_threshold} <- Amount.new(address.dust_threshold) do
      {:ok,
       %__MODULE__{
         id: address.chain,
         chain: address.chain,
         address: address.address,
         halted: address.halted,
         pub_key: String.nil_if_empty(address.pub_key),
         router: String.nil_if_empty(address.router),
         gas_rate: gas_rate,
         gas_rate_units: String.nil_if_empty(address.gas_rate_units),
         outbound_tx_size: outbound_tx_size,
         outbound_fee: outbound_fee,
         dust_threshold: dust_threshold
       }}
    end
  end

  # --- Queries ---

  @doc """
  Memoized list of all chains' inbound addresses.

  Invalidate with `Memoize.invalidate(Rujira.Thorchain.InboundAddress, :list)`.
  """
  @spec list() :: {:ok, [t()]} | {:error, term()}
  defmemo list, expires_in: Rujira.cache_ttl() do
    with {:ok, %QueryInboundAddressesResponse{inbound_addresses: addresses}} <-
           Rujira.Node.query(&Stub.inbound_addresses/2, %QueryInboundAddressesRequest{}) do
      Rujira.Enum.reduce_while_ok(addresses, &new/1)
    end
  end
end
