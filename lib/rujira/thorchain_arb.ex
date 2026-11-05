defmodule Rujira.ThorchainArb do
  @moduledoc """
  Public API for the rujira-thorchain-arb protocol: the arb guards that FIN
  pairs list under `arb_market_makers` and VS v2 strategies name as their
  `arb_guard`.

  Pure delegation facade. Each resource module owns its struct, construction,
  and queries. Invalidation is `Rujira.Cache`'s: it follows from a read's
  sources, not from a call here.

  Every query takes a trailing `opts`, forwarded to `Rujira.Node.query/3`, so a
  caller can read at one `height:`.

  The arb contract emits only plain `wasm` attribute events, which are not
  routed, so there is no `Rujira.ThorchainArb.Events`.
  """

  alias Rujira.ThorchainArb.Guard
  alias Rujira.ThorchainArb.Status

  # --- Guard ---

  defdelegate get(address, opts \\ []), to: Guard
  defdelegate list(opts \\ []), to: Guard
  defdelegate from_id(id, opts \\ []), to: Guard

  # --- Status ---

  @doc "A guard's live status - whether it is paused - cached per block."
  defdelegate status(address, opts \\ []), to: Status, as: :get
end
