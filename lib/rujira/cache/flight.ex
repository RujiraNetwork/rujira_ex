defmodule Rujira.Cache.Flight do
  @moduledoc """
  Single-flight: one node read per `{gen, query_key, height}`, however many
  callers want it.

  The key always carries the height, on the frontier path as well as the exact
  one. A caller at `h + 1` must never join a flight at `h` and be handed the
  value of the wrong height - and the frontier's own key has no height in it.
  A frontier-path caller and an exact-path caller at the same height do
  coalesce, which is right: it is the same fact. Each of them stores the result
  the way its own path stores.

  ## Protocol

  The runner, having won `insert_new`:

    1. runs the fetch;
    2. stores the value - on success only, never an error;
    3. deletes its own in-flight row with `delete_object`;
    4. takes the waiters and replies to each.

  A waiter:

    1. reads the in-flight row;
    2. monitors the runner with an alias, and registers that alias;
    3. re-reads the in-flight row, and starts over from the store lookup if it
       is gone or now belongs to another runner - otherwise a result broadcast
       between steps 1 and 2 would be lost;
    4. blocks until the reply, the runner's `:DOWN`, or its own deadline.

  ## Errors

  An error is broadcast to every waiter and stored nowhere, so twenty callers
  of a failing key wait one node deadline between them rather than twenty. A
  caller that arrives after the broadcast finds no row and fetches again - it
  arrived after the failure, so that is not a retry of it.

  ## Runner deaths

  `Rujira.Enum` kills sibling tasks on the first error and on a timeout, so a
  runner being killed mid-flight is the ordinary case, not the rare one.
  Waiters take the dead runner's row out, race for it, and the winner runs -
  and they keep doing so until their own deadline rather than once, because a
  second kill is just as likely as the first.

  ## Mailbox hygiene

  Readers run in the consumer's own processes - GenServers, LiveViews, channel
  processes - and some of them crash on an unexpected `handle_info`. So a reply
  goes to an `alias()` that is deactivated on every exit path
  (`demonitor(ref, [:flush])`), and anything that was already in flight when
  the waiter gave up is drained before it returns. Nothing is left behind.

  ## Deadline

  A waiter blocks for the fan-out timeout that governs its own call, plus a
  margin: `opts[:fan_out][:timeout]`, else the consumer's configured
  `Rujira.fan_out/0`, else the `Rujira.Enum` default - the same resolution the
  enclosing fan-out uses. Inside a fan-out the enclosing task's own timeout
  kills the waiter first; the deadline is the backstop for everything else, and
  it never outlives the task it runs in by more than the margin. The runner is
  bounded by the node implementation's own deadline.
  """

  alias Rujira.Cache.Tables

  @margin 5_000
  @default_timeout 15_000

  @type key :: {non_neg_integer(), term(), term()}
  @type result :: {:ok, term()} | {:error, term()}

  @doc """
  Returns the stored value for `key`, joins the flight that is fetching it, or
  runs the fetch.

  `lookup` re-reads the caller's own store, `fun` performs the node read and
  `store` files a successful result the way the caller's path files it.
  """
  @spec run(key(), keyword(), (-> {:ok, term()} | :miss), (-> result()), (term() -> :ok)) ::
          result()
  def run(key, opts, lookup, fun, store) do
    attempt(key, lookup, fun, store, System.monotonic_time(:millisecond) + timeout(opts))
  end

  # --- Private ---

  defp attempt(key, lookup, fun, store, deadline) do
    case lookup.() do
      {:ok, value} -> {:ok, value}
      :miss -> race(key, lookup, fun, store, deadline)
    end
  end

  defp race(key, lookup, fun, store, deadline) do
    case :ets.insert_new(Tables.flight(), {key, :running, self()}) do
      true -> lead(key, fun, store)
      false -> follow(key, lookup, fun, store, deadline)
    end
  end

  defp lead(key, fun, store) do
    result = fun.()
    keep(result, store)
    finish(key, result)
    result
  catch
    kind, reason ->
      finish(key, {:error, :flight_crashed})
      :erlang.raise(kind, reason, __STACKTRACE__)
  end

  defp finish(key, result) do
    :ets.delete_object(Tables.flight(), {key, :running, self()})

    Tables.waiters()
    |> :ets.take(key)
    |> Enum.each(fn {_key, ref} -> send(ref, {__MODULE__, key, result}) end)
  end

  defp keep({:ok, value}, store), do: store.(value)
  defp keep(_result, _store), do: :ok

  defp follow(key, lookup, fun, store, deadline) do
    case :ets.lookup(Tables.flight(), key) do
      [{^key, :running, pid}] -> join(key, pid, lookup, fun, store, deadline)
      _ -> retry(key, lookup, fun, store, deadline)
    end
  end

  defp join(key, pid, lookup, fun, store, deadline) do
    ref = Process.monitor(pid, alias: :demonitor)
    :ets.insert(Tables.waiters(), {key, ref})

    case :ets.lookup(Tables.flight(), key) do
      [{^key, :running, ^pid}] -> await(key, pid, ref, lookup, fun, store, deadline)
      _ -> restart(key, ref, lookup, fun, store, deadline)
    end
  end

  defp await(key, pid, ref, lookup, fun, store, deadline) do
    receive do
      {__MODULE__, ^key, result} ->
        cancel(key, ref)
        keep(result, store)
        result

      {:DOWN, ^ref, :process, ^pid, _reason} ->
        :ets.delete_object(Tables.waiters(), {key, ref})
        :ets.delete_object(Tables.flight(), {key, :running, pid})
        retry(key, lookup, fun, store, deadline)
    after
      remaining(deadline) ->
        cancel(key, ref)
        {:error, :timeout}
    end
  end

  defp restart(key, ref, lookup, fun, store, deadline) do
    cancel(key, ref)
    retry(key, lookup, fun, store, deadline)
  end

  defp retry(key, lookup, fun, store, deadline) do
    case remaining(deadline) do
      0 -> {:error, :timeout}
      _ -> attempt(key, lookup, fun, store, deadline)
    end
  end

  defp cancel(key, ref) do
    :ets.delete_object(Tables.waiters(), {key, ref})
    Process.demonitor(ref, [:flush])
    drain(key)
  end

  defp drain(key) do
    receive do
      {__MODULE__, ^key, _result} -> :ok
    after
      0 -> :ok
    end
  end

  defp remaining(deadline), do: max(deadline - System.monotonic_time(:millisecond), 0)

  defp timeout(opts) do
    per_call = fan_out_timeout(Keyword.get(opts, :fan_out))
    configured = fan_out_timeout(Rujira.fan_out())

    (per_call || configured || @default_timeout) + @margin
  end

  defp fan_out_timeout(fan_out) when is_list(fan_out) do
    case Keyword.keyword?(fan_out) && Keyword.get(fan_out, :timeout) do
      timeout when is_integer(timeout) and timeout > 0 -> timeout
      _ -> nil
    end
  end

  defp fan_out_timeout(_fan_out), do: nil
end
