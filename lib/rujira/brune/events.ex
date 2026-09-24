defmodule Rujira.Brune.Events do
  @moduledoc """
  Parser for Brune wasm events.

  Transforms `%Event{}` into a `%BruneEvent{address, data}` envelope.
  Sub-events are pure data constructors that receive a plain attrs map.
  """

  alias Rujira.Brune.Events.Burn
  alias Rujira.Brune.Events.Event, as: BruneEvent
  alias Rujira.Brune.Events.FeeAllocate
  alias Rujira.Brune.Events.FeeDistribute
  alias Rujira.Brune.Events.Mint
  alias Rujira.Brune.Events.NodeBond
  alias Rujira.Brune.Events.NodeDeregister
  alias Rujira.Brune.Events.NodeLeave
  alias Rujira.Brune.Events.NodeRegister
  alias Rujira.Brune.Events.NodeUnbond
  alias Rujira.Brune.Events.Warn
  alias Rujira.Events.Event

  @spec parse(Event.t()) :: {:ok, BruneEvent.t()} | {:error, term()}

  def parse(
        %Event{
          type: "wasm-rujira-brune/" <> action,
          attributes: %{"_contract_address" => address} = attrs
        } = event
      ) do
    case new(action, attrs) do
      {:ok, data} -> {:ok, BruneEvent.new(address, data)}
      {:error, _} = err -> err
      :pass -> {:ok, BruneEvent.new(address, event)}
    end
  end

  def parse(%Event{} = event), do: {:ok, BruneEvent.new(nil, event)}

  defp new("mint", attrs), do: Mint.new(attrs)
  defp new("burn", attrs), do: Burn.new(attrs)
  defp new("node.register", attrs), do: NodeRegister.new(attrs)
  defp new("node.deregister", attrs), do: NodeDeregister.new(attrs)
  defp new("node.leave", attrs), do: NodeLeave.new(attrs)
  defp new("node.bond", attrs), do: NodeBond.new(attrs)
  defp new("node.unbond", attrs), do: NodeUnbond.new(attrs)
  defp new("fee.allocate", attrs), do: FeeAllocate.new(attrs)
  defp new("fee.distribute", attrs), do: FeeDistribute.new(attrs)
  defp new("warn", attrs), do: Warn.new(attrs)
  defp new(_, _), do: :pass
end
