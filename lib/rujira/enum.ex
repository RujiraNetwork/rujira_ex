defmodule Rujira.Enum do
  @moduledoc """
  Custom enum utilities for safer and more efficient list processing.

  ## Fan-out policy

  Every concurrent fan-out in this library goes through
  `reduce_async_while_ok/4`, which owns the whole policy - how long one item
  may take and how many run at once. Call sites pass their query `opts` down
  and name themselves; they carry no timeout or concurrency of their own.

  The policy is read from the `:fan_out` keyword, by key, in this order:

    1. `opts[:fan_out]` - the caller's query opts, per call.
    2. `config :rujira_ex, fan_out: [...]` - the consumer's app env, via
       `Rujira.fan_out/0`.
    3. The defaults: `timeout: 15_000`, `max_concurrency:
       System.schedulers_online()`.

  Precedence is per key, so a per-call `timeout:` leaves a configured
  `max_concurrency:` in place. Both values must be positive integers, and no
  other key is allowed in either source - anything else is
  `{:error, :invalid_fan_out}`, returned before a single item runs.

  `:timeout` is per item, not for the whole fan-out. An item that outlives it
  is killed and the fan-out returns `{:error, {:timeout, label}}`, where
  `label` is the module that called the helper.

  `opts` itself is never altered: the same keyword the caller passed is what
  `fun` closes over, so a nested read - and a nested fan-out - is governed by
  the consumer's `fan_out` too. `Rujira.Node.query/3` drops the key before the
  node implementation sees it.
  """

  alias Rujira.Node

  @fan_out_keys [:timeout, :max_concurrency]

  @doc """
  Iterates over an enumerable, applying a function that returns `{:ok, value}`, `{:error, reason}`, or `:skip`.

  - Accumulates all returned values into a list.
  - Halts and returns `{:error, reason}` if any element returns an error.
  - Skips over elements if `:skip` is returned.
  - Returns `{:ok, list}` when all elements succeed.
  """
  @spec reduce_while_ok(Enumerable.t(), list(), (term() ->
                                                   {:ok, term()} | {:error, term()} | :skip)) ::
          {:ok, list()} | {:error, term()}
  def reduce_while_ok(enum, initial_acc \\ [], fun) do
    Enum.reduce_while(enum, {:ok, initial_acc}, fn element, {:ok, acc} ->
      case fun.(element) do
        {:ok, el} ->
          {:cont, {:ok, [el | acc]}}

        {:error, reason} ->
          {:halt, {:error, reason}}

        :skip ->
          {:cont, {:ok, acc}}
      end
    end)
    |> finalize_reduce_result()
  end

  defp finalize_reduce_result({:ok, acc}), do: {:ok, Enum.reverse(acc)}
  defp finalize_reduce_result({:error, reason}), do: {:error, reason}

  @doc """
  Returns a list of unique elements from the given enumerable, preserving order.
  """
  @spec uniq(Enumerable.t()) :: list()
  def uniq(enum) do
    {_, acc} =
      Enum.reduce(enum, {MapSet.new(), []}, fn x, {seen, acc} ->
        if MapSet.member?(seen, x) do
          {seen, acc}
        else
          {MapSet.put(seen, x), [x | acc]}
        end
      end)

    Enum.reverse(acc)
  end

  @doc """
  Runs `fun` concurrently over `enum`, short-circuiting on the first error and
  collecting only successful results.

  `opts` is the caller's query opts, forwarded unchanged to `fun`'s closure;
  `label` is the calling module, which names the fan-out in a timeout error.
  The `:fan_out` keyword inside `opts` governs the run - see the moduledoc for
  the precedence, the defaults and the validation. Results keep the input
  order.

  Per item, `fun` may return `{:ok, value}`, a bare value, `{:error, reason}`
  or `:skip`. An item that outlives the resolved `:timeout` is killed and the
  whole fan-out returns `{:error, {:timeout, label}}` - or `{:error, :timeout}`
  when no `label` was given. Any other exit or error is returned as
  `{:error, reason}`.
  """
  @spec reduce_async_while_ok(Enumerable.t(), (term() -> term()), Node.opts(), module() | nil) ::
          {:ok, list()} | {:error, term()}
  def reduce_async_while_ok(enum, fun, opts \\ [], label \\ nil) when is_function(fun, 1) do
    with {:ok, fan_out} <- fan_out(opts) do
      enum
      |> Task.async_stream(fun, Keyword.put(fan_out, :on_timeout, :kill_task))
      |> reduce_while_ok([], &handle_async_result(&1, label))
    end
  end

  @doc """
  Runs a fixed list of zero-arity `funs` concurrently, each an independent
  read, and returns their results positionally as `{:ok, [r1, r2, ...]}`.

  Built on `reduce_async_while_ok/4`, so it shares the same `:fan_out` policy,
  `opts` and `label` - see the moduledoc. `Task.async_stream/3` is ordered by
  default, so the first error returned is the first one in `funs`' own order,
  not the first to finish: a fun later in the list that fails before an
  earlier one still yields the earlier fun's outcome first.

  Each fun returns `{:ok, value}` or `{:error, reason}`, as the reads it
  wraps do. Use this only when the funs are independent of each other's
  result - a fun that needs another's value first is a dependency, not a
  fan-out.
  """
  @spec all_async_while_ok([(-> {:ok, term()} | {:error, term()})], Node.opts(), module() | nil) ::
          {:ok, [term()]} | {:error, term()}
  def all_async_while_ok(funs, opts \\ [], label \\ nil) when is_list(funs) do
    reduce_async_while_ok(funs, & &1.(), opts, label)
  end

  defp fan_out(opts) do
    with {:ok, config} <- fan_out_keyword(Rujira.fan_out()),
         {:ok, per_call} <- fan_out_keyword(Keyword.get(opts, :fan_out, [])) do
      fan_out_defaults()
      |> Keyword.merge(config)
      |> Keyword.merge(per_call)
      |> validate_fan_out()
    end
  end

  defp fan_out_defaults, do: [timeout: 15_000, max_concurrency: System.schedulers_online()]

  defp fan_out_keyword(value) when is_list(value) do
    if Keyword.keyword?(value) and Enum.all?(value, &(elem(&1, 0) in @fan_out_keys)) do
      {:ok, value}
    else
      {:error, :invalid_fan_out}
    end
  end

  defp fan_out_keyword(_value), do: {:error, :invalid_fan_out}

  defp validate_fan_out(fan_out) do
    with :ok <- validate_fan_out_values(fan_out), do: {:ok, fan_out}
  end

  defp validate_fan_out_values([]), do: :ok

  defp validate_fan_out_values([{_key, value} | rest]) when is_integer(value) and value > 0,
    do: validate_fan_out_values(rest)

  defp validate_fan_out_values(_fan_out), do: {:error, :invalid_fan_out}

  defp handle_async_result({:ok, {:ok, val}}, _label), do: {:ok, val}
  defp handle_async_result({:ok, {:error, reason}}, _label), do: {:error, reason}
  defp handle_async_result({:ok, :skip}, _label), do: :skip
  defp handle_async_result({:ok, val}, _label), do: {:ok, val}
  defp handle_async_result({:exit, :timeout}, nil), do: {:error, :timeout}
  defp handle_async_result({:exit, :timeout}, label), do: {:error, {:timeout, label}}
  defp handle_async_result({:exit, reason}, _label), do: {:error, reason}
  defp handle_async_result({:error, reason}, _label), do: {:error, reason}
  defp handle_async_result(_result, _label), do: {:error, :unexpected_result}
end
