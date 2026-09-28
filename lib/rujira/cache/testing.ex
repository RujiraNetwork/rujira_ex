defmodule Rujira.Cache.Testing do
  @moduledoc """
  Setting the cache up from a consumer's own test suite.

  A heightless read is served at the head, and before the first
  `Rujira.Node.advance/1` there is none - so a test that reads without
  `height:` has to put a head there first, and one that asserts
  `{:error, :no_head}` has to take it away again. Both are global state, so a
  case using these must run sync:

      use ExUnit.Case, async: false

      setup do
        Rujira.Cache.Testing.reset!()
        Rujira.Cache.Testing.set_head(1_000_000)
        on_exit(&Rujira.Cache.Testing.reset!/0)
      end

  These are the only supported way in: the cache's tables are an
  implementation detail and a test that writes them directly will break
  without notice.
  """

  alias Rujira.Cache.Tables
  alias Rujira.Node
  alias Rujira.Thorchain.Block

  @doc """
  Moves the head to `height` with no node fetch.

  It advances with an empty block at `height`, which is a block
  `Rujira.Node.advance/1` does not have to fetch. Only that one height is
  handed over, so a jump of more than one block above the current head still
  fetches the blocks in between - set the head from an empty cache, or one
  height at a time.

  An empty block changes no source, so nothing already cached is invalidated.
  """
  @spec set_head(pos_integer()) :: :ok | {:error, term()}
  def set_head(height), do: Node.advance(%Block{height: height, events: []})

  @doc """
  Empties every store and leaves no head at all.

  The next heightless read is `{:error, :no_head}` until `set_head/1` puts one
  back. The generation, the markers and the target go with it, so nothing
  carries into the next test.
  """
  @spec reset!() :: :ok
  defdelegate reset!(), to: Tables
end
