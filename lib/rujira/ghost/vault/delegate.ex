defmodule Rujira.Ghost.Vault.Delegate do
  @moduledoc """
  A delegated debt obligation on a Ghost vault.

  Struct, construction, and queries. Use `Rujira.Ghost` as the public API.
  """

  alias Rujira.Amount
  alias Rujira.Cache
  alias Rujira.Contracts
  alias Rujira.Ghost.Vault.Borrower
  alias Rujira.Math
  alias Rujira.Node

  # --- Struct ---

  defstruct borrower: nil, address: nil, current: 0, shares: Decimal.new(0)

  @type t :: %__MODULE__{
          borrower: Borrower.t() | nil,
          address: String.t() | nil,
          current: Amount.t(),
          shares: Decimal.t()
        }

  # --- Construction ---

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"borrower" => borrower, "addr" => addr, "current" => current, "shares" => shares}) do
    with {:ok, borrower} <- Borrower.new(borrower),
         {:ok, current} <- Amount.new(current),
         {:ok, shares} <- Math.to_decimal(shares) do
      {:ok, %__MODULE__{borrower: borrower, address: addr, current: current, shares: shares}}
    end
  end

  def new(_), do: {:error, :invalid_attrs}

  # --- Queries ---

  @spec get(String.t(), String.t(), String.t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def get(vault, borrower, address, opts \\ []) do
    with {:ok, res} <- query(vault, borrower, address, opts) do
      new(res)
    end
  end

  @doc "A delegate's raw position on a vault, cached per `Rujira.Cache`."
  @spec query(String.t(), String.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def query(vault, borrower, address), do: query(vault, borrower, address, [])

  @doc """
  As `query/3`, cached per `Rujira.Cache`; resolved at `opts[:height]` or the
  head.
  """
  @spec query(String.t(), String.t(), String.t(), Node.opts()) ::
          {:ok, map()} | {:error, term()}
  def query(vault, borrower, address, opts) do
    with {:ok, opts} <- Cache.pin(opts) do
      Cache.fetch(
        {__MODULE__, :query, [vault, borrower, address]},
        [:per_block],
        opts,
        fn _height -> fetch(vault, borrower, address, opts) end
      )
    end
  end

  # --- Private ---

  defp fetch(vault, borrower, address, opts) do
    Contracts.query_state_smart(vault, %{delegate: %{borrower: borrower, addr: address}}, opts)
  end
end
