defmodule Rujira.Thorchain.Block.Messages.Message do
  @moduledoc """
  A transaction message this library holds no struct for, kept whole.

  `type_url` is the message's `@type` as the chain spells it, and `data` is the
  message exactly as the node rendered it, so nothing a block carried is lost.
  A message whose `@type` this library does know but whose body it cannot parse
  arrives here too, after a warning - see `Rujira.Thorchain.Block.Messages`.

  A message that carried no `@type` at all has a `nil` `type_url`.
  """

  defstruct type_url: nil, data: %{}

  @type t :: %__MODULE__{type_url: String.t() | nil, data: map()}

  @spec new(String.t() | nil, map()) :: t()
  def new(type_url, data), do: %__MODULE__{type_url: type_url, data: data}
end
