defmodule Rujira.Brune.Events.NodeLeave do
  @moduledoc "A node leave event (`wasm-rujira-brune/node.leave`)."

  defstruct node: nil

  @type t :: %__MODULE__{node: String.t()}

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"node" => node}), do: {:ok, %__MODULE__{node: node}}
  def new(_), do: {:error, :invalid_attrs}
end
