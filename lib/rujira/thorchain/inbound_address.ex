defmodule Rujira.Thorchain.InboundAddress do
  @moduledoc """
  A chain's inbound (vault) address and gas/fee parameters.

  Struct, construction, and queries. Use `Rujira.Thorchain` as the public API.
  """

  alias Rujira.Amount
  alias Rujira.Cache
  alias Rujira.Node
  alias Rujira.String
  alias Thorchain.Types.Query.Stub
  alias Thorchain.Types.QueryInboundAddressesRequest
  alias Thorchain.Types.QueryInboundAddressesResponse
  alias Thorchain.Types.QueryInboundAddressResponse

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

  @doc "All chains' inbound addresses, cached per `Rujira.Cache`."
  @spec list() :: {:ok, [t()]} | {:error, term()}
  def list, do: list([])

  @doc "As `list/0`, read at `opts[:height]` or, without one, at the head."
  @spec list(Node.opts()) :: {:ok, [t()]} | {:error, term()}
  def list(opts) do
    with {:ok, opts} <- Cache.pin(opts) do
      Cache.fetch({__MODULE__, :list, []}, [:per_block], opts, fn _height -> fetch(opts) end)
    end
  end

  @spec from_id(String.t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def from_id(chain, opts \\ []) do
    with {:ok, addresses} <- list(opts) do
      case Enum.find(addresses, &(&1.chain == chain)) do
        nil -> {:error, :not_found}
        address -> {:ok, address}
      end
    end
  end

  # --- Private ---

  defp fetch(opts) do
    with {:ok, %QueryInboundAddressesResponse{inbound_addresses: addresses}} <-
           Node.query(&Stub.inbound_addresses/3, %QueryInboundAddressesRequest{}, opts) do
      Rujira.Enum.reduce_while_ok(addresses, &new/1)
    end
  end
end
