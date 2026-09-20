defmodule Rujira.Thorchain.Address do
  @moduledoc """
  Helpers for deriving THORChain addresses.
  """

  @doc "Derives a THORChain module account address from a module name."
  @spec module_address(binary()) :: String.t()
  def module_address(name) do
    name
    |> then(&:crypto.hash(:sha256, &1))
    |> binary_part(0, 20)
    |> Bech32.convertbits(8, 5, false)
    |> then(&Bech32.encode_from_5bit("thor", &1))
  end
end
