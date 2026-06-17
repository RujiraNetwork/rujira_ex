defmodule Rujira.Ghost.Vault.Interest do
  @moduledoc "The interest-rate curve configuration for a Ghost vault."

  alias Rujira.Math

  defstruct target_utilization: Decimal.new(0),
            base_rate: Decimal.new(0),
            step1: Decimal.new(0),
            step2: Decimal.new(0)

  @type t :: %__MODULE__{
          target_utilization: Decimal.t(),
          base_rate: Decimal.t(),
          step1: Decimal.t(),
          step2: Decimal.t()
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{
        "target_utilization" => target_utilization,
        "base_rate" => base_rate,
        "step1" => step1,
        "step2" => step2
      }) do
    with {:ok, target_utilization} <- Math.to_decimal(target_utilization),
         {:ok, base_rate} <- Math.to_decimal(base_rate),
         {:ok, step1} <- Math.to_decimal(step1),
         {:ok, step2} <- Math.to_decimal(step2) do
      {:ok,
       %__MODULE__{
         target_utilization: target_utilization,
         base_rate: base_rate,
         step1: step1,
         step2: step2
       }}
    end
  end

  def new(_), do: {:error, :invalid_attrs}
end
