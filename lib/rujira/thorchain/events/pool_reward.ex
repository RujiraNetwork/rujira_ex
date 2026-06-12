defmodule Rujira.Thorchain.Events.PoolReward do
  @moduledoc """
  A single pool's share of a `rewards` event.

  The amount is signed: a pool can pay rewards *into* the bond, in which case
  the value is negative — so it is a plain integer rather than an `Amount`.
  """

  alias Rujira.Assets.Asset

  defstruct asset: nil, amount: 0

  @type t :: %__MODULE__{
          asset: Asset.t(),
          amount: integer()
        }
end
