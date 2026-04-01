defmodule Rujira.Fin do
  @moduledoc """
  Rujira's 100% on-chain, central limit order book style decentralized token exchange.

  Stateless query API for FIN protocol contracts. Uses Memoize for caching.
  Consumers invalidate via `Memoize.invalidate(Rujira.Fin, :function, [args])`.
  """

  alias Rujira.Assets
  alias Rujira.Contracts
  alias Rujira.Deployments
  alias Rujira.Deployments.Target
  alias Rujira.Fin.Book
  alias Rujira.Fin.Order
  alias Rujira.Fin.Pair
  alias Rujira.Fin.Range
  alias Rujira.Logger

  use Memoize

  # --- Pair queries ---

  @spec get_pair(String.t()) :: {:ok, Pair.t()} | {:error, GRPC.RPCError.t()}
  def get_pair(address) do
    Contracts.get({Pair, address})
  end

  @spec list_pairs :: {:ok, list(Pair.t())} | {:error, term()}
  defmemo list_pairs do
    with {:ok, targets} <- Deployments.list_targets(Pair) do
      Rujira.Enum.reduce_while_ok(targets, [], fn
      %{status: :preview} = target ->
        Pair.from_target(target)

      %{module: module, address: address} ->
        case Contracts.get({module, address}) do
          {:ok, v} ->
            {:ok, v}

          {:error, err} ->
            Logger.error(Pair, "#{address} error #{inspect(err)}")
            :skip
        end
    end)
    end
  end

  @spec get_stable_pair(String.t()) :: {:ok, Pair.t()} | {:error, term()}
  def get_stable_pair(base_denom) do
    with {:ok, pairs} <- list_pairs(),
         %Pair{} = pair <-
           Enum.find(
             pairs,
             &(&1.token_base == base_denom && &1.deployment_status == :live &&
                 (String.contains?(&1.token_quote, "usdc") ||
                    String.contains?(&1.token_quote, "usdt")))
           ) do
      {:ok, pair}
    else
      nil -> {:error, :not_found}
      err -> err
    end
  end

  @spec get_pair_from_denoms(String.t(), String.t()) :: {:ok, Pair.t()} | {:error, term()}
  defmemo get_pair_from_denoms(base_denom, quote_denom) do
    with {:ok, pairs} <- list_pairs(),
         %Pair{} = pair <-
           Enum.find(
             pairs,
             &(&1.token_base == base_denom && &1.token_quote == quote_denom)
           ) do
      {:ok, pair}
    else
      nil -> {:error, :not_found}
      err -> err
    end
  end

  # --- Book queries ---

  @spec load_pair(Pair.t(), integer()) :: {:ok, Pair.t()} | {:error, GRPC.RPCError.t()}
  def load_pair(pair, limit \\ 75)

  def load_pair(%{deployment_status: :preview} = pair, _limit) do
    {:ok, %{pair | book: Book.empty(pair.address)}}
  end

  def load_pair(pair, limit) do
    with {:ok, res} <- query_book(pair.address, limit),
         {:ok, book} <- Book.from_query(pair.address, res) do
      {:ok, %{pair | book: book}}
    else
      {:error, err} ->
        Logger.error(__MODULE__, "load_pair #{pair.address} #{inspect(err)}")
        {:ok, %{pair | book: Book.empty(pair.address)}}
    end
  end

  @spec query_book(String.t(), integer()) :: {:ok, map()} | {:error, GRPC.RPCError.t()}
  defmemo query_book(contract, limit \\ 100) do
    Contracts.query_state_smart_with_retry(contract, %{book: %{limit: limit}})
  end

  @spec book_from_id(String.t()) :: {:ok, Book.t()} | {:error, term()}
  def book_from_id(id) do
    with {:ok, res} <- get_pair(id),
         {:ok, %{book: book}} <- load_pair(res, 100) do
      {:ok, book}
    end
  end

  @spec book_price(String.t()) :: {:ok, map()} | {:error, term()}
  def book_price(id) do
    with {:ok, book} <- book_from_id(id) do
      {:ok, %{price: book.center, change: 0}}
    end
  end

  # --- Order queries ---

  @spec list_orders(Pair.t(), String.t()) ::
          {:ok, list(Order.t())} | {:error, GRPC.RPCError.t()}
  def list_orders(pair, address, limit \\ 30)
  def list_orders(%{deployment_status: :preview}, _, _), do: {:ok, []}

  def list_orders(pair, address, limit) do
    case query_orders(pair.address, address, limit) do
      {:ok, %{"orders" => orders}} ->
        Rujira.Enum.reduce_while_ok(orders, &Order.from_query(pair, &1))

      err ->
        err
    end
  end

  @spec query_orders(String.t(), String.t(), integer()) ::
          {:ok, map()} | {:error, GRPC.RPCError.t()}
  defmemo query_orders(contract, address, limit \\ 30) do
    Contracts.query_state_smart_with_retry(contract, %{
      orders: %{owner: address, limit: limit}
    })
  end

  @spec list_all_orders(String.t()) :: {:ok, list(Order.t())} | {:error, term()}
  def list_all_orders(address) do
    with {:ok, pairs} <- list_pairs(),
         {:ok, orders} <-
           Rujira.Enum.reduce_async_while_ok(pairs, &list_orders(&1, address), timeout: 15_000) do
      {:ok, List.flatten(orders)}
    end
  end

  @doc """
  Lists all orders for a pair as raw `Order.t()` structs, with opts for height pinning.
  """
  @spec list_pair_orders(Pair.t(), keyword()) :: {:ok, list(Order.t())} | {:error, term()}
  def list_pair_orders(%Pair{} = pair, opts) do
    with {:ok, raw_orders} <- query_all_orders(pair.address, opts) do
      Rujira.Enum.reduce_while_ok(raw_orders, &Order.from_query(pair, &1))
    end
  end

  @spec load_order(Pair.t(), String.t(), String.t(), String.t()) ::
          {:ok, Order.t()} | {:error, term()}
  def load_order(%{address: address} = pair, side, price, owner) do
    case query_order(address, owner, side, price) do
      {:ok, order} ->
        Order.from_query(pair, order)

      {:error, %GRPC.RPCError{status: 2, message: "NotFound: query wasm contract failed"}} ->
        {:ok, Order.new(address, side, price, owner)}

      err ->
        err
    end
  end

  defmemop query_order(address, owner, side, price) do
    Contracts.query_state_smart(
      address,
      %{order: [owner, side, Order.decode_price(price)]}
    )
  end

  # --- Range queries ---

  @spec list_ranges(Pair.t(), String.t() | nil, keyword()) ::
          {:ok, list(Range.t())} | {:error, GRPC.RPCError.t()}
  def list_ranges(pair, address \\ nil, opts \\ [])
  def list_ranges(%{deployment_status: :preview}, _, _), do: {:ok, []}

  def list_ranges(pair, address, opts) do
    case query_ranges(pair.address, address, opts) do
      {:ok, ranges} when is_list(ranges) ->
        Rujira.Enum.reduce_while_ok(ranges, [], &Range.from_query(pair, &1))

      err ->
        err
    end
  end

  @spec query_ranges(String.t(), String.t() | nil, keyword(), String.t() | nil, integer()) ::
          {:ok, list()} | {:error, term()}
  defmemo query_ranges(contract, address, opts, cursor \\ nil, limit \\ 30) do
    Contracts.query_state_smart(
      contract,
      %{ranges: %{owner: address, cursor: cursor, limit: limit}},
      opts
    )
    |> Contracts.paginate("ranges", limit, fn ranges ->
      query_ranges(contract, address, opts, List.last(ranges)["idx"], limit)
    end)
  end

  defmemop query_range(address, idx) do
    Contracts.query_state_smart(
      address,
      %{range: Kernel.to_string(idx)}
    )
  end

  @spec load_range(Pair.t(), integer()) :: {:ok, Range.t()} | {:error, term()}
  def load_range(%{address: address} = pair, idx) do
    case query_range(address, idx) do
      {:ok, range} ->
        Range.from_query(pair, range)

      {:error, %GRPC.RPCError{status: 2, message: "NotFound: query wasm contract failed"}} ->
        {:ok, Range.new(address, idx)}

      err ->
        err
    end
  end

  @spec list_all_ranges(String.t() | nil, list(String.t()) | nil) ::
          {:ok, list(Range.t())} | {:error, term()}
  def list_all_ranges(address \\ nil, contracts \\ nil)

  def list_all_ranges(address, nil) do
    with {:ok, pairs} <- list_pairs() do
      pairs
      |> Enum.filter(&(&1.deployment_status == :live))
      |> collect_ranges(address)
    end
  end

  def list_all_ranges(address, contracts) when is_list(contracts) do
    with {:ok, pairs} <- Rujira.Enum.reduce_while_ok(contracts, [], &get_pair/1) do
      collect_ranges(pairs, address)
    end
  end

  # --- ID routing ---

  @spec pair_from_id(String.t()) :: {:ok, Pair.t()} | {:error, term()}
  def pair_from_id("sthor" <> _ = address), do: get_pair(address)
  def pair_from_id("thor" <> _ = address), do: get_pair(address)

  def pair_from_id(assets) do
    with {:ok, pair} <- lookup_pair(assets) do
      {:ok, %{pair | id: assets}}
    end
  end

  @spec order_from_id(String.t()) :: {:ok, Order.t()} | {:error, term()}
  def order_from_id(id) do
    with [pair_address, side, price, owner] <- String.split(id, "/"),
         {:ok, pair} <- get_pair(pair_address) do
      load_order(pair, side, price, owner)
    else
      {:error, err} -> {:error, err}
      _ -> {:error, :invalid_id}
    end
  end

  @spec range_from_id(String.t()) :: {:ok, Range.t()} | {:error, term()}
  def range_from_id(id) do
    with [pair_address, idx] <- String.split(id, "/"),
         {idx, ""} <- Integer.parse(idx),
         {:ok, pair} <- get_pair(pair_address) do
      load_range(pair, idx)
    else
      {:error, err} -> {:error, err}
      _ -> {:error, :invalid_id}
    end
  end

  @spec ticker_id!(Pair.t()) :: String.t()
  def ticker_id!(%Pair{token_base: token_base, token_quote: token_quote}) do
    {:ok, base} = Assets.from_denom(token_base)
    {:ok, target} = Assets.from_denom(token_quote)

    "#{Assets.label(base)}_#{Assets.label(target)}"
  end

  # --- TVL ---

  @spec get_pair_tvl(String.t()) :: {:ok, non_neg_integer()} | {:error, term()}
  def get_pair_tvl(address) do
    case get_pair(address) do
      {:ok, %Pair{market_makers: market_makers} = pair} ->
        mm_tvl = market_makers |> Enum.map(&mm_tvl_or_zero/1) |> Enum.sum()

        case range_tvl(pair) do
          {:ok, r_tvl} -> {:ok, mm_tvl + r_tvl}
          {:error, _} = err -> err
        end

      _ ->
        {:ok, 0}
    end
  end

  @spec range_tvl(Pair.t()) :: {:ok, non_neg_integer()} | {:error, term()}
  def range_tvl(%Pair{} = pair) do
    case list_ranges(pair) do
      {:ok, ranges} -> {:ok, Enum.reduce(ranges, 0, fn r, acc -> acc + r.value_usd end)}
      {:error, _} = err -> err
    end
  end

  @spec total_range_tvl :: {:ok, non_neg_integer()} | {:error, term()}
  def total_range_tvl do
    case list_pairs() do
      {:ok, pairs} ->
        pairs
        |> Enum.filter(&(&1.deployment_status == :live))
        |> Rujira.Enum.reduce_async_while_ok(
          fn pair ->
            case range_tvl(pair) do
              {:ok, _} = ok -> ok
              {:error, _} -> {:ok, 0}
            end
          end,
          timeout: 30_000
        )
        |> case do
          {:ok, tvls} -> {:ok, Enum.sum(tvls)}
          {:error, _} = err -> err
        end

      {:error, _} = err ->
        err
    end
  end

  # --- Private ---

  defp query_all_orders(contract, opts, start_after \\ nil, limit \\ 30)

  defp query_all_orders(contract, opts, nil, limit) do
    do_query_all_orders(contract, opts, nil, limit)
  end

  defp query_all_orders(contract, opts, %{"owner" => o, "side" => s, "price" => p}, limit) do
    do_query_all_orders(contract, opts, [o, s, p], limit)
  end

  defp do_query_all_orders(contract, opts, cursor, limit) do
    Contracts.query_state_smart(
      contract,
      %{orders: %{owner: nil, start_after: cursor, limit: limit}},
      opts
    )
    |> Contracts.paginate("orders", limit, fn orders ->
      query_all_orders(contract, opts, List.last(orders), limit)
    end)
  end

  defp collect_ranges(pairs, address) do
    with {:ok, ranges} <-
           Rujira.Enum.reduce_async_while_ok(pairs, &list_ranges(&1, address), timeout: 15_000) do
      {:ok, List.flatten(ranges)}
    end
  end

  defp lookup_pair(assets) do
    with [b, q] <- String.split(assets, "/"),
         {:ok, pairs} <- list_pairs(),
         %Pair{} = pair <-
           Enum.find(
             pairs,
             &(Assets.eq_denom(
                 Assets.from_shortcode(b),
                 &1.token_base
               ) and
                 Assets.eq_denom(
                   Assets.from_shortcode(q),
                   &1.token_quote
                 ))
           ) do
      {:ok, pair}
    else
      nil -> {:error, :not_found}
      _ -> {:error, :invalid_id}
    end
  end

  defp mm_tvl_or_zero(mm) do
    case get_mm_tvl(mm) do
      {:ok, tvl} -> tvl
      _ -> 0
    end
  end

  defp get_mm_tvl(mm) do
    with {:ok, %Target{module: module}} <- Deployments.from_address(mm),
         {:ok, pool} <- module.pool_from_id(mm) do
      {:ok, module.tvl(pool)}
    end
  end
end
