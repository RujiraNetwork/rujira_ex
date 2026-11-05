defmodule Rujira.Node.Subscription.BackoffTest do
  use ExUnit.Case, async: true

  alias Rujira.Node.Subscription.Backoff

  test "doubles per attempt up to the cap, between half and all of it" do
    low = fn _n -> 1 end
    high = fn n -> n end

    assert for(a <- 0..6, do: Backoff.delay(a, 500, 30_000, high)) ==
             [500, 1_000, 2_000, 4_000, 8_000, 16_000, 30_000]

    assert for(a <- 0..6, do: Backoff.delay(a, 500, 30_000, low)) ==
             [250, 500, 1_000, 2_000, 4_000, 8_000, 15_000]

    assert Backoff.delay(10_000, 500, 30_000, high) == 30_000
  end

  test "is random within the range and never zero" do
    for attempt <- 0..30, _ <- 1..20 do
      delay = Backoff.delay(attempt, 500, 30_000)
      nominal = min(30_000, 500 * Integer.pow(2, min(attempt, 20)))
      assert delay in div(nominal, 2)..nominal
    end

    assert Backoff.delay(0, 1, 1, fn _ -> 1 end) == 1
  end
end
