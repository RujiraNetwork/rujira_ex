defmodule Rujira.Revenue.Events do
  @moduledoc """
  Parser for Revenue wasm events.

  Transforms `%Event{}` into a `%RevenueEvent{address, data}` envelope.
  Sub-events are pure data constructors that receive a plain attrs map.
  """

  alias Rujira.Events.Event
  alias Rujira.Revenue.Events.Event, as: RevenueEvent
  alias Rujira.Revenue.Events.Run

  @spec parse(Event.t()) :: {:ok, RevenueEvent.t()} | {:error, term()}

  def parse(
        %Event{
          type: "wasm-rujira-revenue/" <> action,
          attributes: %{"_contract_address" => address} = attrs
        } = event
      ) do
    case new(action, attrs) do
      {:ok, data} -> {:ok, RevenueEvent.new(address, data)}
      {:error, _} = err -> err
      :pass -> {:ok, RevenueEvent.new(address, event)}
    end
  end

  def parse(%Event{} = event), do: {:ok, RevenueEvent.new(nil, event)}

  defp new("run", attrs), do: Run.new(attrs)
  defp new(_, _), do: :pass
end
