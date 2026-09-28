defmodule Rujira.Ghost.Credit do
  @moduledoc """
  A Ghost credit contract: the money-market front end that opens credit accounts,
  collateralises them and borrows from Ghost vaults on their behalf.

  The struct is the contract's own `config`. `borrows` is the set of vault
  borrower positions the contract itself holds - loaded with `load/2`, and
  `:not_loaded` until then.

  Struct, construction, and queries. Use `Rujira.Ghost` as the public API.
  """

  alias Rujira.Assets
  alias Rujira.Cache
  alias Rujira.Contracts
  alias Rujira.Deployments
  alias Rujira.Ghost.Vault.Borrower
  alias Rujira.Math
  alias Rujira.Node

  defmodule CollateralRatio do
    @moduledoc """
    The share of a collateral asset's value that counts towards an account's
    borrowing power. An asset absent from the set is not accepted as collateral.
    """

    alias Rujira.Assets.Asset

    defstruct asset: nil, ratio: Decimal.new(0)

    @type t :: %__MODULE__{asset: Asset.t() | nil, ratio: Decimal.t()}
  end

  # --- Struct ---

  defstruct id: nil,
            address: nil,
            code_id: 0,
            collateral_ratios: [],
            fee_liquidation: Decimal.new(0),
            fee_liquidator: Decimal.new(0),
            fee_address: nil,
            liquidation_max_slip: Decimal.new(0),
            liquidation_threshold: Decimal.new(0),
            adjustment_threshold: Decimal.new(0),
            full_liquidation_threshold: 0,
            borrows: :not_loaded

  @type t :: %__MODULE__{
          id: String.t() | nil,
          address: String.t() | nil,
          code_id: non_neg_integer(),
          collateral_ratios: [CollateralRatio.t()],
          fee_liquidation: Decimal.t(),
          fee_liquidator: Decimal.t(),
          fee_address: String.t() | nil,
          liquidation_max_slip: Decimal.t(),
          liquidation_threshold: Decimal.t(),
          adjustment_threshold: Decimal.t(),
          full_liquidation_threshold: non_neg_integer(),
          borrows: :not_loaded | [Borrower.t()]
        }

  # --- Construction ---

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{
        "address" => address,
        "code_id" => code_id,
        "collateral_ratios" => collateral_ratios,
        "fee_liquidation" => fee_liquidation,
        "fee_liquidator" => fee_liquidator,
        "fee_address" => fee_address,
        "liquidation_max_slip" => liquidation_max_slip,
        "liquidation_threshold" => liquidation_threshold,
        "adjustment_threshold" => adjustment_threshold,
        "full_liquidation_threshold" => full_liquidation_threshold
      })
      when is_map(collateral_ratios) do
    with {:ok, code_id} <- Math.to_integer(code_id),
         {:ok, collateral_ratios} <- collateral_ratios(collateral_ratios),
         {:ok, fee_liquidation} <- Math.to_decimal(fee_liquidation),
         {:ok, fee_liquidator} <- Math.to_decimal(fee_liquidator),
         {:ok, liquidation_max_slip} <- Math.to_decimal(liquidation_max_slip),
         {:ok, liquidation_threshold} <- Math.to_decimal(liquidation_threshold),
         {:ok, adjustment_threshold} <- Math.to_decimal(adjustment_threshold),
         {:ok, full_liquidation_threshold} <- Math.to_integer(full_liquidation_threshold) do
      {:ok,
       %__MODULE__{
         id: address,
         address: address,
         code_id: code_id,
         collateral_ratios: collateral_ratios,
         fee_liquidation: fee_liquidation,
         fee_liquidator: fee_liquidator,
         fee_address: fee_address,
         liquidation_max_slip: liquidation_max_slip,
         liquidation_threshold: liquidation_threshold,
         adjustment_threshold: adjustment_threshold,
         full_liquidation_threshold: full_liquidation_threshold
       }}
    end
  end

  def new(_), do: {:error, :invalid_attrs}

  # --- Queries ---

  @spec get(String.t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def get(address, opts \\ []), do: Contracts.get({__MODULE__, address}, opts)

  @doc "A credit contract's id is its address, so this is `get/2`."
  @spec from_id(String.t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def from_id(id, opts \\ []), do: get(id, opts)

  @doc """
  Lists every deployed credit contract.

  Each contract is read concurrently and the list fails as a whole;
  `opts[:fan_out]` sets the per-contract timeout and how many run at once - see
  `Rujira.Enum`.
  """
  @spec list(Node.opts()) :: {:ok, [t()]} | {:error, term()}
  def list(opts \\ []) do
    with {:ok, targets} <- Deployments.list_targets(__MODULE__, opts) do
      Rujira.Enum.reduce_async_while_ok(
        targets,
        fn %{address: address} -> Contracts.get({__MODULE__, address}, opts) end,
        opts,
        __MODULE__
      )
    end
  end

  @doc "Loads the contract's own vault borrower positions into `borrows`."
  @spec load(t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def load(%__MODULE__{address: address} = credit, opts \\ []) do
    with {:ok, borrows} <- query_borrows(address, opts) do
      {:ok, %{credit | borrows: borrows}}
    end
  end

  @doc "The vault borrower positions held by the credit contract, cached per `Rujira.Cache`."
  @spec query_borrows(String.t()) :: {:ok, [Borrower.t()]} | {:error, term()}
  def query_borrows(address), do: query_borrows(address, [])

  @doc """
  As `query_borrows/1`, cached per `Rujira.Cache`; resolved at `opts[:height]`
  or the head.
  """
  @spec query_borrows(String.t(), Node.opts()) :: {:ok, [Borrower.t()]} | {:error, term()}
  def query_borrows(address, opts) do
    with {:ok, opts} <- Cache.pin(opts) do
      Cache.fetch({__MODULE__, :query_borrows, [address]}, [:per_block], opts, fn _height ->
        fetch_borrows(address, opts)
      end)
    end
  end

  # --- Private ---

  defp fetch_borrows(address, opts) do
    case Contracts.query_state_smart(address, %{borrows: %{}}, opts) do
      {:ok, %{"borrowers" => borrowers}} when is_list(borrowers) ->
        Rujira.Enum.reduce_while_ok(borrowers, [], &Borrower.new/1)

      {:ok, _} ->
        {:error, :invalid_attrs}

      {:error, _} = err ->
        err
    end
  end

  # A `BTreeMap<denom, ratio>` on the wire - keyed by denom, so sorted by denom
  # here too rather than left to map iteration order.
  defp collateral_ratios(ratios) do
    ratios
    |> Enum.sort_by(&elem(&1, 0))
    |> Rujira.Enum.reduce_while_ok([], &collateral_ratio/1)
  end

  defp collateral_ratio({denom, ratio}) when is_binary(denom) do
    with {:ok, asset} <- Assets.from_denom(denom),
         {:ok, ratio} <- Math.to_decimal(ratio) do
      {:ok, %CollateralRatio{asset: asset, ratio: ratio}}
    end
  end

  defp collateral_ratio({_denom, _ratio}), do: {:error, :invalid_denom}
end
