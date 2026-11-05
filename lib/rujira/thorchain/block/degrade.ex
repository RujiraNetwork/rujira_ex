defmodule Rujira.Thorchain.Block.Degrade do
  @moduledoc false

  # How a block treats a slot - an event or a message - whose parse failed.
  # Data the parser cannot read degrades to the generic value; anything else -
  # a node read that failed - is the block's error, so it is never cached and
  # the next call retries. Both are warned about, from `module`, with the slot
  # they happened in.

  alias Rujira.Events
  alias Rujira.Logger

  @doc false
  @spec degrade(term(), module(), String.t(), String.t(), (-> term())) ::
          {:ok, term()} | {:error, term()}
  def degrade(reason, module, noun, slot, generic),
    do: degrade(Events.data_error?(reason), reason, module, noun, slot, generic)

  defp degrade(true, reason, module, noun, slot, generic) do
    warn(module, "unparsed #{noun}", slot, reason)
    {:ok, generic.()}
  end

  defp degrade(false, reason, module, noun, slot, _generic) do
    warn(module, "#{noun} parse failed", slot, reason)
    {:error, reason}
  end

  defp warn(module, what, slot, reason),
    do: Logger.warning(module, "#{what} #{slot} #{inspect(reason)}")
end
