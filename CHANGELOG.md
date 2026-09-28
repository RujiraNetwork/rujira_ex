# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## Unreleased

### Added

- `Rujira.Math.add/2`, `sub/2`, `mul/2`, `div/2` and `sum/1`: the general
  arithmetic entry points behind `mul_floor`/`mul_ceil`/`div_floor` - two
  integers give an integer, any `Decimal` or float operand gives a `Decimal`,
  and `div/2` raises on a zero divisor.
- `Rujira.Deployments.from_id/1,2`, resolving a `Rujira.Deployments.Target` by
  its `id` (its contract `address`) - round-trips with `from_address/1,2`.
- Cache control: `Rujira.Node.advance/1`, `Rujira.Cache.head/0`,
  `invalidate_all/0` and `pin/1`.
- Ghost credit, exposing the rujira-ghost-credit contract (v1.0.4) as typed
  chain data, delegated from the existing `Rujira.Ghost` facade:
  - `Rujira.Ghost.Credit` — the contract's config (`get_credit`/`list_credits`/
    `credit_from_id`/`load_credit`), whose `borrows` loads the vault borrower
    positions the contract itself holds, as `Rujira.Ghost.Vault.Borrower`
    structs, through the cached `query_borrows`.
  - `Rujira.Ghost.Credit.Account` — a credit account with its
    `Rujira.Ghost.Credit.Collateral`, `Rujira.Ghost.Credit.Debt` (a
    `Rujira.Ghost.Vault.Delegate` and its value) and
    `Rujira.Ghost.Credit.LiquidationPreferences`, keyed
    `"<credit>/<account>"` (`credit_account`/`credit_accounts`/
    `credit_accounts_by_owner`/`credit_account_from_id`/
    `credit_account_predict`). `ltv` and every value are the contract's own
    response fields; nothing is re-derived and no total is added.
  - `Rujira.Ghost.Credit.Events` — one struct per emitted event, routed from
    `Rujira.Events.parse/1` under `wasm-rujira-ghost-credit/*`. The `funds`
    attribute of the `account.msg/execute`, `account.msg/send` and
    `liquidate.msg/execute` events has no field: it is a `NativeBalance`
    rendered with no delimiter between coins, so it cannot be split back
    apart.
  - `Rujira.Deployments` now resolves `"rujira-ghost-credit"` contracts to
    `Rujira.Ghost.Credit` by default.
- `Rujira.Revenue` protocol facade, exposing the rujira-revenue contract
  (v1.1.0 and v2.x) as typed chain data: `Rujira.Revenue.Converter` (`get`/
  `list`/`load`/`from_id`, plus cached `query_actions`/`query_status`).
  `Rujira.Deployments` now resolves `"rujira-revenue"` contracts to
  `Rujira.Revenue.Converter` by default.

### Changed (breaking)

- **Caching.** Every read across the library now goes through `Rujira.Cache`
  instead of memoizing or reading the node raw. The consumer implements
  `Rujira.Node` and calls `Rujira.Node.advance/1` on every new height; a
  heightless read is served at the head that call moves, and before the first
  `advance/1` it is `{:error, :no_head}`. A block invalidates exactly the
  cached rows its events touched; `Rujira.Cache.invalidate_all/0` is the only
  fallback for what `advance/1` cannot see. See
  [Caching](guides/caching.md) for the full model. Landed as four groups:
  - **Group A** - `Rujira.Contracts`, `Rujira.Deployments`,
    `Rujira.Assets.Metadata` and `Rujira.Thorchain.Block`:
    - `Rujira.Contracts.code/1,2` is removed - it was `code_info/1,2` under
      another name.
    - `Rujira.Deployments.invalidate/0` is removed. `get_target`,
      `from_address`, `from_id`, `list_all_targets` and `list_targets` derive
      from the one cached `contract_infos/0,1` read, so there is nothing of
      their own to invalidate.
    - `Rujira.Contracts.code_info/1,2` is `{:error, :not_found}` for a code id
      the node holds no code under, cached as the fact it is, rather than the
      node's gRPC error.
    - `Rujira.Assets.Metadata.load_metadata/2` is `{:error, :not_found}` where
      it returned the node's "no metadata for denom" error, and caches that
      fact. `Rujira.Assets.from_denom/2` and `from_id/2` are unchanged: a
      denom the node holds no metadata for is still named here.
    - `Rujira.Thorchain.Block.get/2` no longer expires a cached block on the
      `block_cache_ttl` window; a block is held at its own height, and how
      many are held is the cache's `retention`.
    - `Rujira.Node.at_height` is removed - there is no more uncached height
      path to dispatch to; every read, at any height, goes through
      `Rujira.Cache`.
    - `Rujira.cache_ttl` and `Rujira.block_cache_ttl`, and their
      `cache_ttl`/`block_cache_ttl` app-env keys, are removed along with the
      `Memoize` dependency - nothing expires on a TTL any more.
  - **Group B** - `Rujira.Fin` and `Rujira.Prices.Default`:
    - `Rujira.Fin.Pair.list/0,1` is cached against the code registry and every
      pair it resolved. `denom_for_ticker`, `find_stable`, `find_default`,
      `find_by_denoms` and `from_id` derive from that one list in memory and
      are no longer cached on their own.
    - `Rujira.Fin.Book.query/1,2`, `Rujira.Fin.Order.query/4,5` for an
      oracle-priced order, `Rujira.Fin.Order.query_orders/2,3`,
      `Rujira.Fin.Simulation.query/3,4`, `Rujira.Fin.MarketMaker.Quote.query/5`
      and both `Rujira.Prices.Default` legs are read per block: they move with
      the oracle and the market makers, which announce themselves with no
      event, so each is valid at the height it was read at and no other.
    - `Rujira.Fin.Order.query/4,5` for a fixed price, and every
      `Rujira.Fin.Range` query, are cached against the pair contract alone, so
      a block that does not touch it carries them over.
    - `Rujira.Fin.Simulation.query/3,4` keys on the offer asset's native
      denom and `Rujira.Fin.MarketMaker.Quote.query/5` on the offer and ask
      denoms plus `min_price`'s wire form, rather than on the structs they
      arrive in.
    - `Rujira.Prices.Default.oracle_price/1,2` and `fin_price/1,2` no longer
      expire on the `cache_ttl`; a price is held at its own height.
    - `Rujira.Fin.denom_for_ticker/1,2` and `get_pair_from_denoms/2,3` keep
      both arities, now as one function with a default `opts`.
  - **Group C** - `Rujira.Ghost.Vault.Status`, `.Borrower`, `.Delegate`,
    `Rujira.Ghost.Credit` (`query_borrows`), `Rujira.Ghost.Credit.Account`
    (`query_account`, `query_accounts_by_owner`, `query_all_accounts`),
    `Rujira.Staking.Pool.Status`, `Rujira.Staking.Pool.Account`,
    `Rujira.Brune.State`, `Rujira.Revenue.Converter` (`query_actions`,
    `query_status`) and `Rujira.ThorchainSwap.Strategy` (`query_markets`,
    `query_vaults`):
    - `Rujira.Ghost.Credit.Account.predict/4` and
      `Rujira.Brune.LoggedEvent.list/4` are now cached, against
      `{:contract, address}`.
    - `Rujira.Revenue.Converter.query_actions/1,2` and `query_status/1,2`,
      and `Rujira.ThorchainSwap.Strategy.query_markets/1,2` and
      `query_vaults/1,2`, are `{:error, :invalid_response}` for a reply
      missing its expected key, rather than caching the raw, malformed map as
      a success.
  - **Group D** - `Rujira.Thorchain.Network`, `Mimir`, `Pool`,
    `InboundAddress`, `OutboundFee` and `LiquidityProvider`, and
    `Rujira.Bank.Balance`, `Supply` and `Holder`:
    - `Bank.Balance.get/3, list/2, list_spendable/2` and `Bank.Supply.get/2`
      are newly cached (previously uncached node reads);
      `Bank.Holder.holders/1,2` drops its 1-hour TTL.
    - `Bank.Supply.list/1` (every denom's supply) has no single invalidation
      tag, so it is cached against `:per_block` rather than carried over.
  - **Not-found and heights, across the groups:**
    - `Rujira.Fin.Order.query/4,5`, `Rujira.Fin.Range.query/2,3` and
      `query_dynamic/2,3`, and `Rujira.Ghost.Credit.Account`'s account reads
      cache a domain not-found as the fact it is, under the read's own
      sources, and still return `{:error, :not_found}`. `Rujira.Prices.Default`
      does the same for `{:error, :no_price}`, per height.
    - `Rujira.Staking.Pool.Account.load/3` answers an owner the contract holds
      no record for with an empty account (`bonded` and `pending_revenue`
      zero) instead of `{:error, :not_found}`. The staking contract never
      removes an account, so a missing row means a fully unbonded one.
    - Every public opts-taking entry point resolves its height once with
      `Rujira.Cache.pin/1`, so a `list` fan-out reads every item at one
      height even if the head moves under it.
    - `Rujira.Brune.LoggedEvent.list/1-4` returns
      `{:error, :invalid_response}` for a reply missing `events`, rather than
      the raw reply.
- A token-factory (`x/…`) denom takes its symbol, ticker and decimals from the
  denom metadata THORChain holds for it, and the `Asset` carries that metadata.
  A denom the node holds no metadata for is still named here: `x/brune` is
  `bRUNE` and `x/staking-<bond denom>` is `s` + the bond's ticker; anything else
  is the denom with `x/` stripped, as the chain spells it, rather than upcased.
  Any other node error is returned unchanged from `Rujira.Assets.from_denom/2`
  rather than falling back to a derived name. Tickers consumers see change with
  it, among them:
  - `x/staking-x/brune` — `sbRUNE` -> `ybRUNE`
  - `x/staking-x/ruji` — `sRUJI` (unchanged), `x/staking-tcy` — `sTCY`
    (unchanged)
  - ghost-vault receipts — `GHOST-VAULT/BTC-BTC` -> `LEND-BTC.BTC`
  - BOW LP shares — `BOW-XYK-…` -> `LP-BTC.BTC/ETH.USDC-XYK`
  - a generic denom — `x/foo` -> `foo`, not `FOO`
- `Rujira.Assets.from_id/2` takes `Rujira.Node.opts()` and resolves an `x/…` id
  exactly as `from_denom/2` does, so one id always yields one asset — which
  means it reads the node for those ids, and can return a node error.
  `Rujira.Assets.from_string/1` stays pure and names an `x/…` id after the id.
- `Rujira.Assets.Metadata.decimals` is the chain's own: the exponent of the
  display unit in `denom_units`, or the largest exponent declared, and `nil`
  when the metadata declares no unit (it was `0`, always overwritten by the
  per-chain default). `Rujira.Assets.decimals/1` uses an asset's metadata
  decimals when it carries them, so `x/…/hans` is 6, not 8, and
  `Rujira.Assets.load_metadata/2` returns the chain's decimals for an `x/`
  denom rather than the per-chain default.
- Token identity fields that held a raw denom string now hold an
  `Rujira.Assets.Asset.t()`, resolved with `Rujira.Assets.from_denom/1` (an
  unrecognised denom is now `{:error, :invalid_denom}` from construction,
  not a raw string field) — migration:
  - `Rujira.Ghost.Vault.denom` -> `Rujira.Ghost.Vault.asset`
  - `Rujira.Ghost.Vault.receipt_denom` -> `Rujira.Ghost.Vault.receipt_asset`
  - `Rujira.Ghost.Vault.Borrower.denom` -> `Rujira.Ghost.Vault.Borrower.asset`
  - `Rujira.Fin.Events.TradeRange.Dynamic.denom` ->
    `Rujira.Fin.Events.TradeRange.Dynamic.asset` (`nil` when the contract
    emits no denom for the fill)
  - `Rujira.Fin.Pair.token_base` -> `Rujira.Fin.Pair.asset_base`
  - `Rujira.Fin.Pair.token_quote` -> `Rujira.Fin.Pair.asset_quote`
- `Rujira.Contracts.paginate/4` returns `{:error, :invalid_response}` when a
  page reply lacks the list key or holds a non-list there (previously an
  empty page, or a raise); affects the paged lists of `Rujira.Fin.Order`,
  `Rujira.Fin.Range`, `Rujira.Ghost.Vault.Borrower` and
  `Rujira.Ghost.Credit.Account`.
- `Rujira.Contracts.query_state_smart/3` success is typed as any decoded JSON
  value (`term()`), not `map() | nil`.

### Fixed

- `tor` resolves to `THOR.TOR` (it was read as a token with no chain), and
  `Rujira.Assets.to_native/1` of it is `tor` rather than `thor.tor`.
- `Rujira.Fin.pair_from_id/2` resolves an asset-form id whose ticker the token
  spells in mixed case (`THOR.bRUNE/THOR.RUNE`, `sRUJI`, `yRUNE`): the ticker is
  compared case-insensitively, the chain still exactly. Those pairs were
  `{:error, :not_found}`.
- `Rujira.Fin.list_pair_orders/2` and `Rujira.Fin.list_ranges/3` are now pure
  `defdelegate`s (to the new `Rujira.Fin.Order.list_pair/2` and
  `Rujira.Fin.Range.list_pair/3`), matching every other protocol facade -
  names, arities and results are unchanged.
- `Rujira.Fin.Pair.list/1` now resolves its pair configs concurrently, via
  `Rujira.Enum.reduce_async_while_ok/4`, matching every other protocol list.

## 0.6.1

### Changed

- Fan-out policy: every concurrent list (`Rujira.Contracts.list/2`,
  `Rujira.Brune.Pool.list/1`, `Rujira.Fin.Order.list_all_pairs/2`,
  `Rujira.Fin.Range.list_all/3`, `Rujira.Ghost.Vault.list/1`,
  `Rujira.Staking.Pool.list/1`, `Rujira.ThorchainSwap.Strategy.list/1`) now
  shares one per-item timeout (default `15_000`ms) and one `max_concurrency`
  default (`System.schedulers_online/0`), owned by
  `Rujira.Enum.reduce_async_while_ok/4`. Configure it with `config
  :rujira_ex, fan_out: [...]` or per call with `fan_out:` in `opts`; the
  previous hard-coded 5 s/15 s/30 s per-call budgets are gone. A budget
  overrun is now `{:error, {:timeout, module}}`, not `{:error, :timeout}` —
  migration: match the tuple. An unknown key or a non-positive-integer value
  in `:fan_out` (per call or in config) is `{:error, :invalid_fan_out}`.
  `:fan_out` never reaches the node implementation — gRPC stubs reject
  unknown options, and the gRPC call deadline stays the node implementation's
  own setting.

### Fixed

- **`Rujira.Prices.Default`**: the oracle's "Price not found" reply is now
  recognised on both serving paths — gRPC status 2 (Unknown) from the node's
  own gRPC server, and status 3 (InvalidArgument, `"...: invalid request"`)
  through the Cosmos SDK's ABCI query path — so a ticker with no oracle price
  reaches the FIN fallback again instead of surfacing the raw node error on
  the ABCI path.

## 0.6.0

Breaking release: rujira_ex now returns chain data as typed structs whose
fields are exactly what the chain returned for the entity asked for, computed
only from that same read. See "Typed chain access" in
[`guides/conventions.md`](guides/conventions.md).

### Breaking

- **`Rujira.Fin.Order`**: removed the `value_usd` field. Value a position with
  `Rujira.Prices.value_usd/4` over `remaining`/`filled` and the pair's
  tickers yourself.
- **`Rujira.Fin.Range`**: removed the `value_usd` field. Value a range's
  totals with `Rujira.Prices.value_usd/4` yourself.
- **`Rujira.Thorchain.LiquidityProvider`**: removed the `value_usd` field, and
  `new/2` (with `opts`) is now `new/1`. Value `asset_redeem_value` /
  `rune_redeem_value` with `Rujira.Prices.value_usd/4` yourself, at the height
  the position was read.
- **`Rujira.Fin.Order`**: removed the `filled_fee` field. Use
  `Rujira.Fin.order_filled_fee/2` (`Order.filled_fee/2`), a pure function over
  the order and its pair.
- **`Rujira.Fin.pair_tvl`/`get_pair_tvl`, `range_tvl`, `total_range_tvl`,
  `Fin.Pair.tvl/2`, `Fin.Range.tvl/2`, `Fin.Range.total_tvl/1`**: removed.
  Sum a pair's or the protocol's TVL yourself, from `Rujira.Fin.Range` value
  and market-maker state read through their own protocol modules.
- **`Rujira.Fin.book_price/2` (`Fin.Book.price/2`)**: removed. Read
  `book.center` off a loaded `Rujira.Fin.Book` (from `Fin.load_pair/3` or
  `Fin.book_from_id/2`) — its `change` field was always a hardcoded `0`, not a
  real value.
- **`Rujira.Fin.Book`**: `center` and `spread` default to `nil`, not
  `Decimal.new(0)` — a book with a level on only one side has no mid-price or
  spread, and that absence is now `nil` rather than a fake zero.
- **`Rujira.Fin.Book.load/3`**: a book read that fails now returns
  `{:error, reason}`. It previously logged the error and returned
  `{:ok, %{pair | book: %Book{id: pair.address}}}` (an empty placeholder book)
  for every non-height error.
- **`Rujira.Fin.load_pair/3`, `Rujira.Fin.list_orders/4`**: the `limit`
  default changed from `75`/`30` to `nil` (every level/order the contract
  returns). Pass an explicit limit to keep the old page size.
- **`Rujira.Fin.Order.new/3`**: is now `Order.new/2` — it no longer takes
  `opts`, and no longer requires the pair's `fee_maker`/`token_quote`/
  `token_base` (only `pair.address`). Get the filled fee from
  `Order.filled_fee/2` instead.
- **`Rujira.Fin.load_order/5` (`Order.load/5`), `Rujira.Fin.order_from_id/2`**:
  an order the pair does not hold is now `{:error, :not_found}`. Both
  previously returned `{:ok, placeholder}` (a zero-valued order at the
  requested key) for a `NotFound` contract error; `from_id/2` also no longer
  reads the pair's own config to build that order.
- **`Rujira.Fin.range_from_id/2` (`Range.from_id/2`), `Range.load/3`**: a
  range the contract does not hold is now `{:error, :not_found}` instead of a
  placeholder struct; `from_id/2` no longer reads the pair's own config.
- **`Rujira.Fin.Range.new/3`**: is now `Range.new/2` — no `opts`, and no
  longer resolves `token_quote`/`token_base` into assets to price the range.
- **`Rujira.Fin.list_pairs/1` (`Pair.list/1`)**: a pair that fails to read is
  no longer silently skipped from the list — the whole call returns
  `{:error, reason}`. A skipped pair previously made the list read as the set
  of pairs that exist, when one configured pair was actually unreadable.
- **`Rujira.Fin.get_pair/2` (`Pair.get/2`)**: a lookup error that is not a
  height error is now returned unchanged instead of being coerced to
  `{:error, :invalid_id}`.
- **`Rujira.Bank.holders/2`, `Rujira.Bank.holders/3` (`Bank.Holder.holders/2`,
  `holders/3`)**: the `limit` parameter is removed. `holders/1` (was `/2`)
  now memoizes every holder, in node order, not the top 100 by balance
  descending; `holders/2` (was `/3`) is its `opts` sibling. Sort and
  `Enum.take/2` yourself if you need the old top-N-by-balance shape.
- **`Rujira.Bank.Balance.get/3`, `Rujira.Bank.Supply.get/2`**: a bank list
  containing one denom `Rujira.Coin.new/1` cannot parse (e.g. via
  `Rujira.Bank.balances/2` or `supplies/1`) now fails the whole call with
  `{:error, :invalid_denom}` instead of logging and skipping that one coin.
- **`Rujira.Assets.Metadata.load_metadata/2`**: a failed node query now
  returns `{:error, reason}` unchanged instead of `{:ok, fallback}` (a
  placeholder metadata struct built from the denom string).
- **`Rujira.Contracts.version/1`, `version/2`**: a contract with no
  `contract_info` entry (missing contract or entry never written) is now
  `{:error, :not_found}` instead of `{:ok, nil}`.
- **`Rujira.Contracts.get/1`, `get/2`**: now return `{:error, :not_found}` for
  an address with no contract (raw `no such contract` gRPC error) and for a
  contract query that reports the queried item missing (raw `NotFound` error),
  instead of passing the raw gRPC error through. The following facades return
  `:not_found` for an unknown address: `Rujira.Fin.Pair.get/2` and
  `pair_from_id/2`, `Rujira.Ghost.Vault.get/2` and `from_id/2`,
  `Rujira.Staking.Pool.get/2` and `from_id/2`, `Rujira.Brune.Pool.get/2` and
  `from_id/2`, `Rujira.ThorchainSwap.Strategy.get/2` and `from_id/2`. Callers
  that matched `%GRPC.RPCError{}` or other raw error shapes now match
  `{:error, :not_found}` instead.
- **`Rujira.Deployments.get_target/1`**: changed from a bare `Target.t() | nil`
  return to `{:ok, Target.t()} | {:error, :not_found | term()}`, matching
  `get_target/2`.
- **`Rujira.Deployments.list_targets/1`**: changed from a bare `[Target.t()]`
  return to `{:ok, [Target.t()]} | {:error, term()}`, matching
  `list_targets/2`.
- **`Rujira.Ghost.Vault.Account`**: removed the `value` field. Use
  `Rujira.Ghost.vault_account_value/2` (`Account.value/2`), pure over the
  account and a vault whose `status` is loaded.
- **`Rujira.Ghost.Vault.Account.new/3`**: `shares` is no longer optional
  (`\\ 0`); pass it explicitly.
- **`Rujira.Ghost.Vault.Account.load/3`**: no longer loads the vault's
  `Status` as a side effect, and a balance-read error is now returned
  unchanged instead of falling back to `{:ok, new(vault, account)}` (a
  zero-share, zero-value account) for any non-height error.
- **`Rujira.Staking.Pool.Account`**: removed the `liquid_shares` and
  `liquid_size` fields. Read liquid receipt-token shares with
  `Rujira.Bank.balance(owner, pool.receipt_asset, opts)`, and their bonded
  size with `Rujira.Staking.account_liquid_size/2` (`Account.liquid_size/2`),
  pure over the shares and a pool whose `status` is loaded.
- **`Rujira.Staking.Pool.Account.new/4`**: the third positional argument is
  now the contract's raw `pending_revenue`, not `contract_pending_revenue`
  plus the revenue this account would receive on the next distribution; the
  fourth (`liquid_shares`) is removed. Get the projected share with
  `Rujira.Staking.account_revenue_share/2` (`Account.revenue_share/2`).
- **`Rujira.Staking.Pool.Account.load/3`**: no longer auto-loads the pool's
  `Status` when it is `:not_loaded`, and no longer returns a zero-valued
  placeholder account for an owner that has never bonded — that case is now
  `{:error, :not_found}`.
- **`Rujira.Staking.Pool`**: `fee` defaults to `nil`, not `Decimal.new(0)` — an
  unset pool fee is now an absence, not a fake zero rate.
- **`Rujira.Prices`** (`get/2`, `value_usd/3`, `value_usd/4`) and the
  `Rujira.Prices` behaviour's `value_usd` callbacks: `value_usd` now returns
  `{:ok, integer()} | {:error, term()}` instead of a bare `integer()`. A
  custom `Rujira.Prices` implementation must update its `value_usd`
  callback(s) to match; every caller must unwrap `{:ok, usd}` instead of using
  the return value directly.
- **`Rujira.Prices.Default.get/2`**: an oracle error other than "no price for
  this symbol" (a transport failure, an unservable height, a decode error) no
  longer falls back to the FIN mid-price — it is now returned unchanged. Only
  `{:error, :no_price}` from the oracle falls through to FIN.
- **`Rujira.Brune.LoggedEvent`**: `id` is now `"<contract address>/<seq>"`
  (`String.t()`), not the bare integer log sequence. The sequence number
  alone is now the separate `seq` field.
- **`Rujira.Brune.Node`**: `status: :unknown` is removed. An unrecognised node
  status string is now `{:error, :invalid_status}` from `Node.new/1` instead
  of a node with `status: :unknown`; `status` on the struct is `nil` only
  while absent, never a placeholder value.

### Added

- `Rujira.Contracts.not_found?/1` — true when a wasm query error means the
  queried item does not exist (a contract's own `NotFound`, or
  `cosmwasm_std::StdError::NotFound`), false for every other error.
- `Rujira.Fin.order_filled_fee/2` (`Order.filled_fee/2`) — the maker fee on an
  order's filled amount, pure over the order and its pair.
- `Rujira.Staking.account_revenue_share/2` (`Account.revenue_share/2`) — the
  revenue the pool's undistributed revenue will assign to an account on the
  next distribution, pure over the account and a pool whose `status` is
  loaded; `{:error, :not_loaded}` otherwise.
- `Rujira.Staking.account_liquid_size/2` (`Account.liquid_size/2`) — the
  bonded size a parcel of liquid receipt-token shares redeems for, pure over
  a pool whose `status` is loaded; `{:error, :not_loaded}` otherwise.
- `Rujira.Ghost.vault_account_value/2` (`Account.value/2`) — what an
  account's shares redeem for, pure over the account and a vault whose
  `status` is loaded; `{:error, :not_loaded}` otherwise.
- `Rujira.Ghost.Vault.from_id/2` — a vault's id is its address, so this is
  `Vault.get/2`; `Rujira.Ghost.vault_from_id/2` now delegates to it.
- `Rujira.Brune.pool_from_id/2` (`Pool.from_id/2`).
- `Rujira.ThorchainSwap.strategy_from_id/2` (`Strategy.from_id/2`).
- `Rujira.Thorchain.inbound_address_from_id/2` (`InboundAddress.from_id/2`).
- `Rujira.Thorchain.outbound_fee_from_id/2` (`OutboundFee.from_id/2`).

### Fixed

- **`Rujira.Staking.Pool.Account.load/3`**: an owner that has never bonded is
  now matched with `Rujira.Contracts.not_found?/1` instead of a hardcoded
  `"NotFound: query wasm contract failed"` string, which missed the node's
  actual `StdError::NotFound` rendering for this query
  (`"type: ...AccountPoolAccount; key: [..] not found"`).
- **`Rujira.Fin.Pair.tvl/2`**: removed together with the TVL functions — its
  market-maker fallback silently priced a market maker at `0` whenever the
  module it resolved to did not export a `pool_from_id/2` opts arity, masking
  a real integration gap as a zero contribution to TVL.
