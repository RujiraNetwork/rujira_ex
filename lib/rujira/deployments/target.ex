defmodule Rujira.Deployments.Target do
  @moduledoc """
  Defines a deployment target structure for tracking smart contract deployments.
  """
  defstruct [
    :id,
    :address,
    :creator,
    :code_id,
    :salt,
    :admin,
    :protocol,
    :module,
    :config,
    :contract,
    :status
  ]

  @type status :: :live | :pending
end
