defmodule Rujira.Node.Subscription.Backoff do
  @moduledoc """
  The reconnect delay of `Rujira.Node.Subscription`: exponential, capped, with
  jitter.

  Attempt `n` (0 for the first retry) waits a uniformly random time between
  half of `min(max, base * 2^n)` and all of it ("equal jitter"), so a fleet of
  consumers that lost the same node does not reconnect in lockstep, and no
  retry comes sooner than half the nominal delay.
  """

  # 2^20 * any sane base is far past any sane cap; stops the shift growing.
  @max_exponent 20

  @doc """
  The delay in milliseconds before reconnect attempt `attempt`.

  `rand` maps a positive integer `n` to an integer in `1..n`; it defaults to
  `:rand.uniform/1` and is injectable for tests.
  """
  @spec delay(non_neg_integer(), pos_integer(), pos_integer(), (pos_integer() -> pos_integer())) ::
          pos_integer()
  def delay(attempt, base, max, rand \\ &:rand.uniform/1)
      when is_integer(attempt) and attempt >= 0 and is_integer(base) and base > 0 and
             is_integer(max) and max > 0 do
    nominal = min(max, base * Integer.pow(2, min(attempt, @max_exponent)))
    half = div(nominal, 2)
    max(1, half + rand.(nominal - half + 1) - 1)
  end
end
