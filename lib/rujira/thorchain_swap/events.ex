defmodule Rujira.ThorchainSwap.Events do
  @moduledoc """
  Parser for ThorchainSwap wasm events.

  Transforms `%Event{}` into a `%ThorchainSwapEvent{address, data}` envelope.
  Sub-events are pure data constructors that receive a plain attrs map.
  """

  alias Rujira.Events.Event
  alias Rujira.ThorchainSwap.Events.Event, as: ThorchainSwapEvent
  alias Rujira.ThorchainSwap.Events.Swap

  @spec parse(Event.t()) :: {:ok, ThorchainSwapEvent.t()} | {:error, term()}

  def parse(
        %Event{
          type: "wasm-rujira-thorchain-swap/" <> action,
          attributes: %{"_contract_address" => address} = attrs
        } = event
      ) do
    case new(action, attrs) do
      {:ok, data} -> {:ok, ThorchainSwapEvent.new(address, data)}
      {:error, _} = err -> err
      :pass -> {:ok, ThorchainSwapEvent.new(address, event)}
    end
  end

  def parse(%Event{} = event), do: {:ok, ThorchainSwapEvent.new(nil, event)}

  defp new("swap", attrs), do: Swap.new(attrs)
  defp new(_, _), do: :pass
end
