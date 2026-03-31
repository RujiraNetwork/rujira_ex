defmodule Rujira.Account do
  @moduledoc """
  Minimal chain account representation.

  Protocol-specific account types (Bow.Account, Ghost.Credit.Account, etc.)
  live in their respective protocol modules.
  """

  defstruct [:address, :chain]

  @type t :: %__MODULE__{
          address: String.t(),
          chain: String.t()
        }
end
