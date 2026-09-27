defmodule Rujira.Brune.Node do
  @moduledoc """
  A single THORChain node tracked by a rujira-brune pool.

  Struct and construction. Use `Rujira.Brune` as the public API.
  """

  alias Rujira.Amount
  alias Rujira.Math

  # --- Struct ---

  defstruct addr: nil,
            fee: Decimal.new(0),
            bond: 0,
            weight: Decimal.new(0),
            capacity: 0,
            is_leaving: false,
            status: nil,
            node: %{}

  @type status ::
          :whitelisted | :standby | :ready | :active | :disabled

  @type t :: %__MODULE__{
          addr: String.t() | nil,
          fee: Decimal.t(),
          bond: Amount.t(),
          weight: Decimal.t(),
          capacity: Amount.t(),
          is_leaving: boolean(),
          status: status() | nil,
          node: map()
        }

  # --- Construction ---

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{
        "addr" => addr,
        "fee" => fee,
        "bond" => bond,
        "weight" => weight,
        "capacity" => capacity,
        "is_leaving" => is_leaving,
        "status" => status,
        "node" => node
      }) do
    with {:ok, fee} <- Math.to_decimal(fee),
         {:ok, bond} <- Amount.new(bond),
         {:ok, weight} <- Math.to_decimal(weight),
         {:ok, capacity} <- Amount.new(capacity),
         {:ok, status} <- status(status) do
      {:ok,
       %__MODULE__{
         addr: addr,
         fee: fee,
         bond: bond,
         weight: weight,
         capacity: capacity,
         is_leaving: is_leaving,
         status: status,
         node: node
       }}
    end
  end

  def new(_), do: {:error, :invalid_attrs}

  # --- Private ---

  defp status("whitelisted"), do: {:ok, :whitelisted}
  defp status("standby"), do: {:ok, :standby}
  defp status("ready"), do: {:ok, :ready}
  defp status("active"), do: {:ok, :active}
  defp status("disabled"), do: {:ok, :disabled}
  defp status(_), do: {:error, :invalid_status}
end
