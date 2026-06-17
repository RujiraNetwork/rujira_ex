defmodule Rujira.Ghost.Vault do
  @moduledoc """
  A Ghost money-market vault: a single-denom lending pool that whitelisted
  market contracts borrow from.

  Struct, construction, and queries. Use `Rujira.Ghost` as the public API.
  """

  alias Rujira.Contracts
  alias Rujira.Deployments
  alias Rujira.Ghost.Vault.Interest
  alias Rujira.Ghost.Vault.Status
  alias Rujira.Math

  # --- Struct ---

  defstruct id: nil,
            address: nil,
            denom: nil,
            receipt_denom: nil,
            interest: nil,
            fee: Decimal.new(0),
            fee_address: nil,
            status: :not_loaded

  @type t :: %__MODULE__{
          id: String.t() | nil,
          address: String.t() | nil,
          denom: String.t() | nil,
          receipt_denom: String.t() | nil,
          interest: Interest.t() | nil,
          fee: Decimal.t(),
          fee_address: String.t() | nil,
          status: :not_loaded | Status.t()
        }

  # --- Construction ---

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{
        "address" => address,
        "denom" => denom,
        "interest" => interest,
        "fee" => fee,
        "fee_address" => fee_address
      }) do
    with {:ok, interest} <- Interest.new(interest),
         {:ok, fee} <- Math.to_decimal(fee) do
      {:ok,
       %__MODULE__{
         id: address,
         address: address,
         denom: denom,
         receipt_denom: "x/ghost-vault/#{denom}",
         interest: interest,
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
end
