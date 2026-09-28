defmodule Rujira.Cache.Telemetry do
  @moduledoc """
  The cache's `:telemetry` events - see `Rujira.Cache` for what each carries.

  Every event is executed in the calling process, and every emission is
  wrapped: a handler that raises, or a consumer whose `:telemetry` application
  is not running, must never turn a cached read into an error.
  """

  @fetch [:rujira, :cache, :fetch]
  @advance [:rujira, :cache, :advance]
  @reset [:rujira, :cache, :reset]

  @typedoc "The store a read was served from, or filed into."
  @type store :: :frontier | :exact | :identity

  @typedoc "How a read resolved: from the store, from a node read, or not at all."
  @type result :: :hit | :miss | :error

  @typedoc "Why everything was invalidated."
  @type reason :: :catchup | :stuck_block | :upgrade | :invalidate_all

  @doc "Every event this module emits, for a consumer attaching to all of them at once."
  @spec events() :: [[atom()]]
  def events, do: [@fetch, @advance, @reset]

  @doc """
  Reports one resolved read.

  `start` is the `System.monotonic_time/0` the read began at, so the
  measurement covers the store lookup as well as whatever node read followed.
  """
  @spec fetch(store(), result(), Rujira.Cache.query_key(), integer()) :: :ok
  def fetch(store, result, query_key, start) do
    {module, function} = query(query_key)

    execute(@fetch, %{duration: elapsed(start)}, %{
      store: store,
      result: result,
      module: module,
      function: function
    })
  end

  @doc "Reports one fill: the head before and after it, and how many blocks it applied."
  @spec advance(non_neg_integer(), non_neg_integer(), non_neg_integer(), integer()) :: :ok
  def advance(from, to, blocks, start) do
    execute(@advance, %{from: from, to: to, blocks: blocks, duration: elapsed(start)}, %{})
  end

  @doc "Reports one invalidation of everything, at the head it happened at."
  @spec reset(reason(), non_neg_integer(), non_neg_integer()) :: :ok
  def reset(reason, from, to) do
    execute(@reset, %{from: from, to: to}, %{reason: reason})
  end

  # --- Private ---

  # A query key is `{module, function, args}`. The args are left out: they
  # carry addresses and denoms, which would give the metric the cardinality of
  # the chain.
  defp query({module, function, _args}) when is_atom(module) and is_atom(function),
    do: {module, function}

  defp query(_query_key), do: {nil, nil}

  defp elapsed(start), do: System.monotonic_time() - start

  defp execute(event, measurements, metadata) do
    :telemetry.execute(event, measurements, metadata)
  catch
    _kind, _reason -> :ok
  end
end
