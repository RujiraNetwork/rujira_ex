defmodule Rujira.Staking.Pool do
  @moduledoc """
  A rujira-staking pool: bonds a single token and distributes a separate
  revenue token to bonders (directly, or via liquid receipt-token shares).

  Struct, construction, and queries. Use `Rujira.Staking` as the public API.
  """

  alias Rujira.Amount
  alias Rujira.Assets
  alias Rujira.Assets.Asset
  alias Rujira.Contracts
  alias Rujira.Deployments
  alias Rujira.Math
  alias Rujira.Staking.Pool.Status

  defmodule RevenueConverter do
    @moduledoc "Config for converting collected revenue via an external contract call."

    defstruct contract: nil, msg: nil, limit: 0

    @type t :: %__MODULE__{
            contract: String.t() | nil,
            msg: String.t() | nil,
            limit: Amount.t()
          }

    @spec new(list()) :: {:ok, t()} | {:error, term()}
    def new([contract, msg, limit]) do
      with {:ok, limit} <- Amount.new(limit) do
        {:ok, %__MODULE__{contract: contract, msg: msg, limit: limit}}
      end
    end

    def new(_), do: {:error, :invalid_attrs}
  end

  # --- Struct ---

  defstruct id: nil,
            address: nil,
            bond_asset: nil,
            revenue_asset: nil,
            receipt_asset: nil,
            revenue_converter: nil,
            fee: Decimal.new(0),
            fee_address: nil,
            status: :not_loaded

  @type t :: %__MODULE__{
          id: String.t() | nil,
          address: String.t() | nil,
          bond_asset: Asset.t() | nil,
          revenue_asset: Asset.t() | nil,
          receipt_asset: Asset.t() | nil,
          revenue_converter: RevenueConverter.t() | nil,
          fee: Decimal.t(),
          fee_address: String.t() | nil,
          status: :not_loaded | Status.t()
        }

  # --- Construction ---

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{
        "address" => address,
        "bond_denom" => bond_denom,
        "revenue_denom" => revenue_denom,
        "revenue_converter" => revenue_converter,
        "fee" => fee
      }) do
    with {:ok, bond_asset} <- Assets.from_denom(bond_denom),
         {:ok, revenue_asset} <- Assets.from_denom(revenue_denom),
         {:ok, receipt_asset} <- Assets.from_denom("x/staking-" <> bond_denom),
         {:ok, revenue_converter} <- RevenueConverter.new(revenue_converter),
         {:ok, {fee, fee_address}} <- fee(fee) do
      {:ok,
       %__MODULE__{
         id: address,
         address: address,
         bond_asset: bond_asset,
         revenue_asset: revenue_asset,
         receipt_asset: receipt_asset,
         revenue_converter: revenue_converter,
         fee: fee,
         fee_address: fee_address
       }}
    end
  end

  def new(_), do: {:error, :invalid_attrs}

  # --- Queries ---

  @spec get(String.t()) :: {:ok, t()} | {:error, term()}
  def get(address), do: Contracts.get({__MODULE__, address})

  @spec list() :: {:ok, [t()]} | {:error, term()}
  def list do
    __MODULE__
    |> Deployments.list_targets()
    |> Rujira.Enum.reduce_async_while_ok(fn %{address: address} ->
      Contracts.get({__MODULE__, address})
    end)
  end

  @spec from_id(String.t()) :: {:ok, t()} | {:error, term()}
  def from_id(address), do: get(address)

  # --- Private ---

  defp fee(nil), do: {:ok, {Decimal.new(0), nil}}

  defp fee([fee, fee_address]) do
    with {:ok, fee} <- Math.to_decimal(fee) do
      {:ok, {fee, fee_address}}
    end
  end

  defp fee(_), do: {:error, :invalid_attrs}
end
