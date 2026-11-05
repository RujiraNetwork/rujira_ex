defmodule Rujira.Node.Subscription.Telemetry do
  @moduledoc """
  The `:telemetry` events of `Rujira.Node.Subscription` - see its moduledoc
  for what each carries.

  Every emission is wrapped: a handler that raises, or a consumer whose
  `:telemetry` application is not running, never takes the connection down.
  """

  @connect [:rujira, :node, :subscription, :connect]
  @disconnect [:rujira, :node, :subscription, :disconnect]
  @new_block [:rujira, :node, :subscription, :new_block]
  @invalid_frame [:rujira, :node, :subscription, :invalid_frame]

  @doc "Every event this module emits, for a consumer attaching to all of them at once."
  @spec events() :: [[atom()]]
  def events, do: [@connect, @disconnect, @new_block, @invalid_frame]

  @doc """
  Reports a subscription the node acknowledged. `start` is the
  `System.monotonic_time/0` the connection attempt began at; `attempt` is how
  many attempts failed before this one.
  """
  @spec connect(String.t(), non_neg_integer(), integer()) :: :ok
  def connect(url, attempt, start) do
    execute(@connect, %{duration: System.monotonic_time() - start, attempt: attempt}, %{url: url})
  end

  @doc """
  Reports a lost connection or a failed attempt, the reconnect `attempt` it
  starts, and the `delay` in milliseconds before it.
  """
  @spec disconnect(String.t(), term(), non_neg_integer(), pos_integer()) :: :ok
  def disconnect(url, reason, attempt, delay) do
    execute(@disconnect, %{attempt: attempt, delay: delay}, %{url: url, reason: reason})
  end

  @doc "Reports a new block header and how many subscribers it was sent to."
  @spec new_block(String.t(), pos_integer(), non_neg_integer()) :: :ok
  def new_block(url, height, subscribers) do
    execute(@new_block, %{height: height, subscribers: subscribers}, %{url: url})
  end

  @doc "Reports a frame from the node that was ignored, and why."
  @spec invalid_frame(String.t(), term()) :: :ok
  def invalid_frame(url, reason) do
    execute(@invalid_frame, %{count: 1}, %{url: url, reason: reason})
  end

  # --- Private ---

  defp execute(event, measurements, metadata) do
    :telemetry.execute(event, measurements, metadata)
  catch
    _kind, _reason -> :ok
  end
end
