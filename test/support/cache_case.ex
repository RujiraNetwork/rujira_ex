defmodule Rujira.Test.CacheCase do
  @moduledoc """
  An `ExUnit.CaseTemplate` for tests that read through `Rujira.Cache`.

  The cache's tables and its head are global, so a case using this template
  must run sync:

      use Rujira.Test.CacheCase, async: false

  Every test starts from an empty cache at `default_head/0`, and the same state
  is restored afterwards, so a test that moves the head or fills the cache
  cannot leak into the next one.

  Two helpers do the setting up, both of them `Rujira.Cache.Testing` - the
  same module a consumer's own suite uses:

    * `set_head/1` moves the head without a node fetch, by advancing with an
      empty block at that height - `Rujira.Node.advance/1` fetches every block
      it is not handed.
    * `reset_cache/0` empties the tables and leaves no head at all, for a test
      asserting `{:error, :no_head}`.
  """

  use ExUnit.CaseTemplate

  alias Rujira.Cache.Testing

  @default_head 1_000_000

  using do
    quote do
      import Rujira.Test.CacheCase
    end
  end

  setup do
    reset!()
    on_exit(&__MODULE__.reset!/0)
    :ok
  end

  @doc "The head every test starts at, and the one the suite runs under."
  @spec default_head() :: pos_integer()
  def default_head, do: @default_head

  @doc "Empties the cache and puts the head back at `default_head/0`."
  @spec reset!() :: :ok | {:error, term()}
  def reset! do
    reset_cache()
    set_head(@default_head)
  end

  @doc "Empties every store, leaving no head."
  @spec reset_cache() :: :ok
  defdelegate reset_cache(), to: Testing, as: :reset!

  @doc "Moves the head to `height` without fetching a block for it."
  @spec set_head(pos_integer()) :: :ok | {:error, term()}
  defdelegate set_head(height), to: Testing
end
