defmodule Rujira.Thorchain.OutboundFee do
  @moduledoc """
  An asset's outbound fee and the network's fee accounting for it.

  Struct, construction, and queries. Use `Rujira.Thorchain` as the public API.
  """

  alias Rujira.Amount
  alias Thorchain.Types.Query.Stub
  alias Thorchain.Types.QueryOutboundFeeResponse
  alias Thorchain.Types.QueryOutboundFeesRequest
  alias Thorchain.Types.QueryOutboundFeesResponse

  use Memoize

  # --- Struct ---

  defstruct id: nil,
            asset: nil,
            outbound_fee: 0,
            fee_withheld_rune: nil,
            fee_spent_rune: nil,
            surplus_rune: nil,
            dynamic_multiplier_basis_points: nil

  @type t :: %__MODULE__{
          id: String.t() | nil,
          asset: String.t() | nil,
          outbound_fee: Amount.t(),
          fee_withheld_rune: Amount.t() | nil,
          fee_spent_rune: Amount.t() | nil,
          surplus_rune: Amount.t() | nil,
          dynamic_multiplier_basis_points: Amount.t() | nil
        }

  # --- Construction ---

  @spec new(QueryOutboundFeeResponse.t()) :: {:ok, t()} | {:error, term()}
  def new(%QueryOutboundFeeResponse{} = fee) do
    with {:ok, outbound_fee} <- Amount.new(fee.outbound_fee),
         {:ok, fee_withheld_rune} <- Amount.new(fee.fee_withheld_rune),
         {:ok, fee_spent_rune} <- Amount.new(fee.fee_spent_rune),
         {:ok, surplus_rune} <- Amount.new(fee.surplus_rune),
         {:ok, dynamic_multiplier_basis_points} <- Amount.new(fee.dynamic_multiplier_basis_points) do
      {:ok,
       %__MODULE__{
         id: fee.asset,
         asset: fee.asset,
         outbound_fee: outbound_fee,
         fee_withheld_rune: fee_withheld_rune,
         fee_spent_rune: fee_spent_rune,
         surplus_rune: surplus_rune,
         dynamic_multiplier_basis_points: dynamic_multiplier_basis_points
       }}
    end
  end

  # --- Queries ---

  @doc """
  Memoized list of all assets' outbound fees.

  Invalidate with `Memoize.invalidate(Rujira.Thorchain.OutboundFee, :list)`.
  """
  @spec list() :: {:ok, [t()]} | {:error, term()}
  defmemo list, expires_in: Rujira.cache_ttl() do
    with {:ok, %QueryOutboundFeesResponse{outbound_fees: fees}} <-
           Rujira.Node.query(&Stub.outbound_fees/2, %QueryOutboundFeesRequest{}) do
      Rujira.Enum.reduce_while_ok(fees, &new/1)
    end
  end
end
