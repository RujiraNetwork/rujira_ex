defmodule Rujira.Application do
  @moduledoc """
  The library's OTP application.

  It exists for one reason: the cache needs ETS tables and an `:atomics`
  array, and both need an owner that outlives every caller. The supervisor
  starts `Rujira.Cache.Tables`, a passive owner with no behaviour of its own -
  it creates the tables and the atomics in `init/1` and then does nothing. No
  work runs in it: `Rujira.Node.advance/1` and every read run in the caller's
  own process.
  """

  use Application

  alias Rujira.Cache.Tables

  @impl true
  def start(_type, _args) do
    Supervisor.start_link([Tables], strategy: :one_for_one, name: Rujira.Supervisor)
  end
end
