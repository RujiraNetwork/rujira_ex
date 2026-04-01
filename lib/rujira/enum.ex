defmodule Rujira.Enum do
  @moduledoc """
  Custom enum utilities for safer and more efficient list processing.
  """

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
  Runs the given function concurrently over the enum using `Task.async_stream/3`,
  short-circuiting on the first error, and collecting only successful results.
  """
  @spec reduce_async_while_ok(Enumerable.t(), (term() -> term()), keyword()) ::
          {:ok, list()} | {:error, term()}
  def reduce_async_while_ok(enum, fun, opts \\ []) when is_function(fun, 1) do
    Task.async_stream(
      enum,
      fun,
      Keyword.merge(opts, on_timeout: :kill_task)
    )
    |> reduce_while_ok([], &handle_async_result/1)
  end

  defp handle_async_result({:ok, {:ok, val}}), do: {:ok, val}
  defp handle_async_result({:ok, {:error, reason}}), do: {:error, reason}
  defp handle_async_result({:ok, :skip}), do: :skip
  defp handle_async_result({:ok, val}), do: {:ok, val}
  defp handle_async_result({:exit, reason}), do: {:error, reason}
  defp handle_async_result({:error, reason}), do: {:error, reason}
  defp handle_async_result(_), do: {:error, :unexpected_result}
end
