defmodule Rujira.Cache.Invalidator do
  @moduledoc """
  The pure part of `Rujira.Node.advance/1`: which sources a block changed.

  It reads only what the block already carries. It performs no node read, so
  it cannot fail, cannot be slow and cannot degrade on a metadata error - the
  block's own parse may fall back to a raw event, and this still sees
  everything it needs.

  ## What it reads

  A block's events are protocol envelopes, not raw events, and an envelope
  keeps its `_contract_address` as `address` while dropping the rest of the
  attribute map. That loses nothing here: every event this function cares
  about other than a contract's own is unrouted, so it arrives as a raw
  `Rujira.Events.Event` with its attributes intact.

  | Source | From |
  |---|---|
  | `{:contract, address}` | a raw event's `_contract_address`, or an envelope's `address` |
  | `:contract_registry` | `instantiate`, `migrate`, `store_code` |
  | `{:balance, address}` | `coin_spent`'s `spender`, `coin_received`'s `receiver` |
  | `{:denom_transfers, denom}` | every denom in those events' `amount` |
  | `:all` | `version` - the upgrade event, in whatever stage it was emitted |
  | `:per_block` | always |

  Every event of the block counts, from every stage and from failed
  transactions too: a failed transaction still pays its fee, and that moves a
  balance.

  `THOR`-native envelopes (`swap`, `transfer`, `set_mimir`, ...) contribute
  nothing of their own. They change module state, which `:per_block` already
  covers, and they carry no contract address.
  """

  alias Rujira.Brune.Events.Event, as: BruneEvent
  alias Rujira.Events.Event, as: RawEvent
  alias Rujira.Fin.Events.Event, as: FinEvent
  alias Rujira.Ghost.Credit.Events.Event, as: GhostCreditEvent
  alias Rujira.Ghost.Vault.Events.Event, as: GhostVaultEvent
  alias Rujira.Revenue.Events.Event, as: RevenueEvent
  alias Rujira.Staking.Events.Event, as: StakingEvent
  alias Rujira.Thorchain.Block
  alias Rujira.Thorchain.Block.Event, as: BlockEvent
  alias Rujira.ThorchainSwap.Events.Event, as: ThorchainSwapEvent

  @denom_regex ~r|^\s*\d+\s*([a-zA-Z][a-zA-Z0-9/:._-]{2,127})\s*$|

  @doc "Every source `block` changed. Always includes `:per_block`."
  @spec sources(Block.t()) :: [Rujira.Cache.source()]
  def sources(%Block{events: events}) do
    events
    |> Enum.reduce(MapSet.new([:per_block]), &collect/2)
    |> MapSet.to_list()
  end

  # --- Private ---

  defp collect(%BlockEvent{event: event}, acc), do: event(event, acc)
  defp collect(_event, acc), do: acc

  defp event(%RawEvent{type: type, attributes: attrs}, acc) when is_map(attrs) do
    acc
    |> contract(Map.get(attrs, "_contract_address"))
    |> registry(type)
    |> upgrade(type)
    |> transfers(type, attrs)
  end

  defp event(%BruneEvent{address: address}, acc), do: contract(acc, address)
  defp event(%FinEvent{address: address}, acc), do: contract(acc, address)
  defp event(%GhostCreditEvent{address: address}, acc), do: contract(acc, address)
  defp event(%GhostVaultEvent{address: address}, acc), do: contract(acc, address)
  defp event(%RevenueEvent{address: address}, acc), do: contract(acc, address)
  defp event(%StakingEvent{address: address}, acc), do: contract(acc, address)
  defp event(%ThorchainSwapEvent{address: address}, acc), do: contract(acc, address)
  defp event(_event, acc), do: acc

  defp contract(acc, nil), do: acc
  defp contract(acc, ""), do: acc
  defp contract(acc, address), do: MapSet.put(acc, {:contract, address})

  defp registry(acc, type) when type in ~w(instantiate migrate store_code),
    do: MapSet.put(acc, :contract_registry)

  defp registry(acc, _type), do: acc

  defp upgrade(acc, "version"), do: MapSet.put(acc, :all)
  defp upgrade(acc, _type), do: acc

  defp transfers(acc, "coin_spent", attrs),
    do: coins(acc, Map.get(attrs, "spender"), Map.get(attrs, "amount"))

  defp transfers(acc, "coin_received", attrs),
    do: coins(acc, Map.get(attrs, "receiver"), Map.get(attrs, "amount"))

  defp transfers(acc, _type, _attrs), do: acc

  defp coins(acc, address, amount), do: acc |> balance(address) |> denoms(amount)

  defp balance(acc, nil), do: acc
  defp balance(acc, ""), do: acc
  defp balance(acc, address), do: MapSet.put(acc, {:balance, address})

  defp denoms(acc, amount) when is_binary(amount),
    do: amount |> String.split(",") |> Enum.reduce(acc, &denom/2)

  defp denoms(acc, _amount), do: acc

  defp denom(coin, acc) do
    case Regex.run(@denom_regex, coin) do
      [_match, denom] -> MapSet.put(acc, {:denom_transfers, denom})
      _ -> acc
    end
  end
end
