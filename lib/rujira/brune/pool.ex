defmodule Rujira.Brune.Pool do
  @moduledoc """
  A rujira-brune node/bond pool: configuration for a permissioned or
  permissionless set of THORChain nodes bonded and rewarded through the
  contract.

  Struct, construction, and queries. Use `Rujira.Brune` as the public API.
  """

  alias Rujira.Amount
  alias Rujira.Assets
  alias Rujira.Assets.Asset
  alias Rujira.Contracts
  alias Rujira.Deployments
  alias Rujira.Math

  defmodule Range do
    @moduledoc "The pool's target bond-utilization curve."
    defstruct high: Decimal.new(0),
              low: Decimal.new(0),
              skew: Decimal.new(0),
              step: Decimal.new(0)

    @type t :: %__MODULE__{
            high: Decimal.t(),
            low: Decimal.t(),
            skew: Decimal.t(),
            step: Decimal.t()
          }

    @spec new(map()) :: {:ok, t()} | {:error, term()}
    def new(%{"high" => high, "low" => low, "skew" => skew, "step" => step}) do
      with {:ok, high} <- Math.to_decimal(high),
           {:ok, low} <- Math.to_decimal(low),
           {:ok, skew} <- Math.to_decimal(skew),
           {:ok, step} <- Math.to_decimal(step) do
        {:ok, %__MODULE__{high: high, low: low, skew: skew, step: step}}
      end
    end

    def new(_), do: {:error, :invalid_attrs}
  end

  # --- Struct ---

  defstruct id: nil,
            address: nil,
            fin_contract: nil,
            stake_contract: nil,
            token: nil,
            target_utilization: Decimal.new(0),
            min_node_fee: Decimal.new(0),
            range: nil,
            permissionless: false,
            revenue_smear: 0,
            quarantine: {:height, 0},
            nodes_cache_ttl: 0,
            max_bond: 0,
            max_effective_bond: 0,
            mint_cap: 0,
            state: :not_loaded

  @type quarantine :: {:height, integer()} | {:time, integer()}

  @type t :: %__MODULE__{
          id: String.t() | nil,
          address: String.t() | nil,
          fin_contract: String.t() | nil,
          stake_contract: String.t() | nil,
          token: Asset.t() | nil,
          target_utilization: Decimal.t(),
          min_node_fee: Decimal.t(),
          range: Range.t() | nil,
          permissionless: boolean(),
          revenue_smear: integer(),
          quarantine: quarantine(),
          nodes_cache_ttl: integer(),
          max_bond: Amount.t(),
          max_effective_bond: Amount.t(),
          mint_cap: Amount.t(),
          state: :not_loaded | Rujira.Brune.State.t()
        }

  # --- Construction ---

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{
        "address" => address,
        "fin_contract" => fin_contract,
        "stake_contract" => stake_contract,
        "token_id" => token_id,
        "target_utilization" => target_utilization,
        "min_node_fee" => min_node_fee,
        "range" => range,
        "permissionless" => permissionless,
        "revenue_smear" => revenue_smear,
        "quarantine" => quarantine,
        "nodes_cache_ttl" => nodes_cache_ttl,
        "max_bond" => max_bond,
        "max_effective_bond" => max_effective_bond,
        "mint_cap" => mint_cap
      }) do
    with {:ok, target_utilization} <- Math.to_decimal(target_utilization),
         {:ok, min_node_fee} <- Math.to_decimal(min_node_fee),
         {:ok, range} <- Range.new(range),
         {:ok, revenue_smear} <- Math.to_integer(revenue_smear),
         {:ok, quarantine} <- quarantine(quarantine),
         {:ok, nodes_cache_ttl} <- Math.to_integer(nodes_cache_ttl),
         {:ok, max_bond} <- Amount.new(max_bond),
         {:ok, max_effective_bond} <- Amount.new(max_effective_bond),
         {:ok, mint_cap} <- Amount.new(mint_cap),
         {:ok, token} <- Assets.from_denom("x/" <> token_id) do
      {:ok,
       %__MODULE__{
         id: address,
         address: address,
         fin_contract: fin_contract,
         stake_contract: stake_contract,
         token: token,
         target_utilization: target_utilization,
         min_node_fee: min_node_fee,
         range: range,
         permissionless: permissionless,
         revenue_smear: revenue_smear,
         quarantine: quarantine,
         nodes_cache_ttl: nodes_cache_ttl,
         max_bond: max_bond,
         max_effective_bond: max_effective_bond,
         mint_cap: mint_cap
       }}
    end
  end

  def new(_), do: {:error, :invalid_attrs}

  # --- Queries ---

  @spec get(String.t()) :: {:ok, t()} | {:error, term()}
  def get(address), do: Contracts.get({__MODULE__, address})

  @spec list() :: {:ok, [t()]} | {:error, term()}
  def list do
    __MODULE__
    |> Deployments.list_targets()
    |> Rujira.Enum.reduce_async_while_ok(fn %{address: address} ->
      Contracts.get({__MODULE__, address})
    end)
  end

  # --- Private ---

  defp quarantine(%{"height" => height}) do
    with {:ok, height} <- Math.to_integer(height), do: {:ok, {:height, height}}
  end

  defp quarantine(%{"time" => time}) do
    with {:ok, time} <- Math.to_integer(time), do: {:ok, {:time, time}}
  end

  defp quarantine(_), do: {:error, :invalid_attrs}
end
