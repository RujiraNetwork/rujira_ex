defmodule Rujira.Cache.Config do
  @moduledoc """
  The cache's tuning knobs, read from the consumer's app env on each use.

      config :rujira_ex, Rujira.Cache,
        retention: 100,
        max_catchup: 100,
        frontier_max_rows: 100_000,
        max_markers: 100_000,
        sweep_per_block: 1_000,
        lock_timeout: 30_000,
        max_block_failures: 3

  See `Rujira.Cache` for what each one does. They are read per call rather
  than cached, so a consumer can change one at runtime.
  """

  @defaults [
    retention: 100,
    max_catchup: 100,
    frontier_max_rows: 100_000,
    max_markers: 100_000,
    sweep_per_block: 1_000,
    lock_timeout: 30_000,
    max_block_failures: 3
  ]

  @doc "How many distinct heights the exact store holds before it prunes."
  @spec retention() :: pos_integer()
  def retention, do: get(:retention)

  @doc "How far behind the target the head may fall before `advance/1` resets instead of filling."
  @spec max_catchup() :: pos_integer()
  def max_catchup, do: get(:max_catchup)

  @doc "How many rows the frontier holds before the sweep evicts by oldest `as_of`."
  @spec frontier_max_rows() :: pos_integer()
  def frontier_max_rows, do: get(:frontier_max_rows)

  @doc "How many markers are held before the table is collapsed to the marker floor."
  @spec max_markers() :: pos_integer()
  def max_markers, do: get(:max_markers)

  @doc "How many frontier rows one block's sweep visits."
  @spec sweep_per_block() :: pos_integer()
  def sweep_per_block, do: get(:sweep_per_block)

  @doc "How long, in ms, an `advance/1` lock may be held before another caller takes it over."
  @spec lock_timeout() :: pos_integer()
  def lock_timeout, do: get(:lock_timeout)

  @doc "How many consecutive failures of one block `advance/1` takes before resetting."
  @spec max_block_failures() :: pos_integer()
  def max_block_failures, do: get(:max_block_failures)

  # --- Private ---

  defp get(key) do
    :rujira_ex
    |> Application.get_env(Rujira.Cache, [])
    |> Keyword.get(key, Keyword.fetch!(@defaults, key))
  end
end
