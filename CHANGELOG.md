# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## Unreleased

### Added

- Ghost credit, exposing the rujira-ghost-credit contract (v1.0.4) as typed
  chain data, delegated from the existing `Rujira.Ghost` facade:
  - `Rujira.Ghost.Credit` — the contract's config (`get_credit`/`list_credits`/
    `credit_from_id`/`load_credit`), whose `borrows` loads the vault borrower
    positions the contract itself holds, as `Rujira.Ghost.Vault.Borrower`
    structs, through the memoized `query_borrows`.
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
  `list`/`load`/`from_id`, plus memoized `query_actions`/`query_status`).
  `Rujira.Deployments` now resolves `"rujira-revenue"` contracts to
  `Rujira.Revenue.Converter` by default.

### Changed (breaking)

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
