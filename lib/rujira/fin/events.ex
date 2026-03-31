defmodule Rujira.Fin.Events do
  @moduledoc """
  Parser for FIN protocol wasm events.

  Routes event structs to typed struct modules.
  """

  alias Rujira.Events.Event
  alias Rujira.Fin.Events.RangeClaim
  alias Rujira.Fin.Events.RangeClose
  alias Rujira.Fin.Events.RangeCreate
  alias Rujira.Fin.Events.RangeDeposit
  alias Rujira.Fin.Events.RangeFee
  alias Rujira.Fin.Events.RangeWithdraw
  alias Rujira.Fin.Events.Retract
  alias Rujira.Fin.Events.Submit
  alias Rujira.Fin.Events.Trade

  @spec parse(Event.t()) :: {:ok, struct()} | {:error, term()}
  def parse(%Event{type: "wasm-rujira-fin/trade", attributes: attrs}), do: Trade.new(attrs)
  def parse(%Event{type: "wasm-rujira-fin/submit", attributes: attrs}), do: Submit.new(attrs)
  def parse(%Event{type: "wasm-rujira-fin/retract", attributes: attrs}), do: Retract.new(attrs)

  def parse(%Event{type: "wasm-rujira-fin/range.create", attributes: attrs}),
    do: RangeCreate.new(attrs)

  def parse(%Event{type: "wasm-rujira-fin/range.deposit", attributes: attrs}),
    do: RangeDeposit.new(attrs)

  def parse(%Event{type: "wasm-rujira-fin/range.withdraw", attributes: attrs}),
    do: RangeWithdraw.new(attrs)

  def parse(%Event{type: "wasm-rujira-fin/range.close", attributes: attrs}),
    do: RangeClose.new(attrs)

  def parse(%Event{type: "wasm-rujira-fin/range.claim", attributes: attrs}),
    do: RangeClaim.new(attrs)

  def parse(%Event{type: "wasm-rujira-fin/range.fee", attributes: attrs}),
    do: RangeFee.new(attrs)

  def parse(%Event{} = event), do: {:ok, event}
end
