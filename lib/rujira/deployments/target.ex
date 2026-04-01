defmodule Rujira.Deployments.Target do
  @moduledoc """
  Defines a deployment target structure for tracking smart contract deployments.
  """
  defstruct id: nil,
            address: nil,
            creator: nil,
            code_id: nil,
            salt: nil,
            admin: nil,
            protocol: nil,
            module: nil,
            config: nil,
            contract: nil,
            status: nil

  @type status :: :live | :preview

  @type t :: %__MODULE__{
          id: term(),
          address: String.t() | nil,
          creator: String.t() | nil,
          code_id: non_neg_integer() | nil,
          salt: String.t() | nil,
          admin: String.t() | nil,
          protocol: String.t() | nil,
          module: module() | nil,
          config: map() | nil,
          contract: String.t() | nil,
          status: status() | nil
        }
end
