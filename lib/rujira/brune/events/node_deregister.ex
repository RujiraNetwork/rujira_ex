defmodule Rujira.Brune.Events.NodeDeregister do
  @moduledoc "A node deregistration event (`wasm-rujira-brune/node.deregister`)."

  defstruct node: nil

  @type t :: %__MODULE__{node: String.t()}

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"node" => node}), do: {:ok, %__MODULE__{node: node}}
  def new(_), do: {:error, :invalid_attrs}
end
