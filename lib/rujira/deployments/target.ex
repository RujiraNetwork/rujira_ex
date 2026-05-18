defmodule Rujira.Deployments.Target do
  @moduledoc """
  A deployment target resolved from on-chain contract metadata.
  """

  defstruct [:id, :address, :module, :name, :version]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          address: String.t() | nil,
          module: module() | nil,
          name: String.t() | nil,
          version: String.t() | nil
        }
end
