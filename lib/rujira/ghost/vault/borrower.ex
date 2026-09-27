defmodule Rujira.Ghost.Vault.Borrower do
  @moduledoc """
  A whitelisted borrower's position on a Ghost vault.

  Struct, construction, and queries. Use `Rujira.Ghost` as the public API.
  """

  alias Rujira.Amount
  alias Rujira.Contracts
  alias Rujira.Math
  alias Rujira.Node

  use Memoize

  @max_limit 100

  # --- Struct ---

  defstruct address: nil,
            denom: nil,
            limit: 0,
            current: 0,
            shares: Decimal.new(0),
            available: 0

  @type t :: %__MODULE__{
          address: String.t() | nil,
          denom: String.t() | nil,
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
    with {:ok, limit} <- Amount.new(limit),
         {:ok, current} <- Amount.new(current),
         {:ok, shares} <- Math.to_decimal(shares),
         {:ok, available} <- Amount.new(available) do
      {:ok,
       %__MODULE__{
         address: addr,
         denom: denom,
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

  @doc """
  Memoized fetch of a borrower's raw position on a vault.

  Invalidate with `Memoize.invalidate(Rujira.Ghost.Vault.Borrower, :query, [vault, address])`.
  """
  @spec query(String.t(), String.t()) :: {:ok, map()} | {:error, term()}
  defmemo query(vault, address) do
    fetch(vault, address, [])
  end

  @doc """
  As `query/2`, read at `opts[:height]` when one is given - a height read is
  never cached. Without a `:height` this is `query/2`, so the other opts are not
  applied.
  """
  @spec query(String.t(), String.t(), Node.opts()) :: {:ok, map()} | {:error, term()}
  def query(vault, address, opts) do
    Node.at_height(opts, fn -> fetch(vault, address, opts) end, fn -> query(vault, address) end)
  end

  @doc """
  Memoized fetch of all raw borrower positions on a vault, paginated internally.

  Invalidate with `Memoize.invalidate(Rujira.Ghost.Vault.Borrower, :query_borrowers, [vault])`.
  """
  @spec query_borrowers(String.t()) :: {:ok, [map()]} | {:error, term()}
  defmemo query_borrowers(vault) do
    query_borrowers_page(vault, nil, [])
  end

  @doc """
  As `query_borrowers/1`, read at `opts[:height]` when one is given - a height
  read is never cached. Without a `:height` this is `query_borrowers/1`, so the
  other opts are not applied.
  """
  @spec query_borrowers(String.t(), Node.opts()) :: {:ok, [map()]} | {:error, term()}
  def query_borrowers(vault, opts) do
    Node.at_height(
      opts,
      fn -> query_borrowers_page(vault, nil, opts) end,
      fn -> query_borrowers(vault) end
    )
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
