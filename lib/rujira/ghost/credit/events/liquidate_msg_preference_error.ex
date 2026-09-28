defmodule Rujira.Ghost.Credit.Events.LiquidateMsgPreferenceError do
  @moduledoc """
  A preferred liquidation step that failed and was skipped
  (`wasm-rujira-ghost-credit/liquidate.msg/preference.error`).

  The contract ignores the error and carries on with the next step, so this is a
  log line, not a failed liquidation.
  """

  defstruct error: nil

  @type t :: %__MODULE__{error: String.t()}

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"error" => error}) when is_binary(error) do
    {:ok, %__MODULE__{error: error}}
  end

  def new(_), do: {:error, :invalid_attrs}
end
