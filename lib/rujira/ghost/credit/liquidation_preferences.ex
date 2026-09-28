defmodule Rujira.Ghost.Credit.LiquidationPreferences do
  @moduledoc """
  An account owner's liquidation preferences: the route steps the contract
  injects at the start of a liquidation, and the order constraints it enforces
  once those are exhausted.
  """

  alias Rujira.Ghost.Credit.LiquidateMsg
  alias Rujira.Ghost.Credit.LiquidationPreferences.Order

  # --- Struct ---

  defstruct messages: [], order: nil

  @type t :: %__MODULE__{messages: [LiquidateMsg.t()], order: Order.t() | nil}

  # --- Construction ---

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"messages" => messages, "order" => order}) when is_list(messages) do
    with {:ok, messages} <- Rujira.Enum.reduce_while_ok(messages, [], &LiquidateMsg.new/1),
         {:ok, order} <- Order.new(order) do
      {:ok, %__MODULE__{messages: messages, order: order}}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
