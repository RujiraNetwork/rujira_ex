defmodule Rujira.Ghost.Vault.Borrower do
  @moduledoc """
  A whitelisted borrower's position on a Ghost vault.

  Struct, construction, and queries. Use `Rujira.Ghost` as the public API.
  """

  alias Rujira.Amount
  alias Rujira.Assets
  alias Rujira.Assets.Asset
  alias Rujira.Cache
  alias Rujira.Contracts
  alias Rujira.Math
  alias Rujira.Node

  @max_limit 100

  # --- Struct ---

  defstruct address: nil,
            asset: nil,
            limit: 0,
            current: 0,
            shares: Decimal.new(0),
            available: 0

  @type t :: %__MODULE__{
          address: String.t() | nil,
          asset: Asset.t() | nil,
          limit: Amount.t(),
          current: Amount.t(),
          shares: Decimal.t(),
          available: Amount.t()
        }

  # --- Construction ---

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{
        "addr" => addr,
        "denom" => denom,
        "limit" => limit,
        "current" => current,
        "shares" => shares,
        "available" => available
      }) do
    with {:ok, asset} <- Assets.from_denom(denom),
         {:ok, limit} <- Amount.new(limit),
         {:ok, current} <- Amount.new(current),
         {:ok, shares} <- Math.to_decimal(shares),
         {:ok, available} <- Amount.new(available) do
      {:ok,
       %__MODULE__{
         address: addr,
         asset: asset,
         limit: limit,
         current: current,
         shares: shares,
         available: available
       }}
    end
  end

  def new(_), do: {:error, :invalid_attrs}

  # --- Queries ---

  @spec get(String.t(), String.t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def get(vault, address, opts \\ []) do
    with {:ok, res} <- query(vault, address, opts) do
      new(res)
    end
  end

  @spec list(String.t(), Node.opts()) :: {:ok, [t()]} | {:error, term()}
  def list(vault, opts \\ []) do
    with {:ok, borrowers} <- query_borrowers(vault, opts) do
      Rujira.Enum.reduce_while_ok(borrowers, &new/1)
    end
  end

  @doc "A borrower's raw position on a vault, cached per `Rujira.Cache`."
  @spec query(String.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def query(vault, address), do: query(vault, address, [])

  @doc """
  As `query/2`, cached per `Rujira.Cache`; resolved at `opts[:height]` or the
  head.
  """
  @spec query(String.t(), String.t(), Node.opts()) :: {:ok, map()} | {:error, term()}
  def query(vault, address, opts) do
    with {:ok, opts} <- Cache.pin(opts) do
      Cache.fetch({__MODULE__, :query, [vault, address]}, [:per_block], opts, fn _height ->
        fetch(vault, address, opts)
      end)
    end
  end

  @doc "Every raw borrower position on a vault, paginated internally, cached per `Rujira.Cache`."
  @spec query_borrowers(String.t()) :: {:ok, [map()]} | {:error, term()}
  def query_borrowers(vault), do: query_borrowers(vault, [])

  @doc """
  As `query_borrowers/1`, cached per `Rujira.Cache`; resolved at `opts[:height]`
  or the head.
  """
  @spec query_borrowers(String.t(), Node.opts()) :: {:ok, [map()]} | {:error, term()}
  def query_borrowers(vault, opts) do
    with {:ok, opts} <- Cache.pin(opts) do
      Cache.fetch({__MODULE__, :query_borrowers, [vault]}, [:per_block], opts, fn _height ->
        query_borrowers_page(vault, nil, opts)
      end)
    end
  end

  # --- Private ---

  defp fetch(vault, address, opts) do
    Contracts.query_state_smart(vault, %{borrower: %{addr: address}}, opts)
  end

  defp query_borrowers_page(vault, cursor, opts) do
    vault
    |> Contracts.query_state_smart_with_retry(
      %{borrowers: %{start_after: cursor, limit: @max_limit}},
      opts
    )
    |> Contracts.paginate("borrowers", @max_limit, fn borrowers ->
      query_borrowers_page(vault, borrowers |> List.last() |> Map.get("addr"), opts)
    end)
  end
end
