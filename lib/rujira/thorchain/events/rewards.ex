defmodule Rujira.Thorchain.Events.Rewards do
  @moduledoc "A THORChain block rewards event (`rewards`)."

  alias Rujira.Amount
  alias Rujira.Assets
  alias Rujira.Math
  alias Rujira.Thorchain.Events.PoolReward

  defstruct bond_reward: 0,
            dev_fund_reward: 0,
            income_burn: 0,
            tcy_stake_reward: 0,
            marketing_fund_reward: 0,
            pol_reserve_reward: 0,
            pool_rewards: []

  @type t :: %__MODULE__{
          bond_reward: Amount.t(),
          dev_fund_reward: Amount.t(),
          income_burn: Amount.t(),
          tcy_stake_reward: Amount.t(),
          marketing_fund_reward: Amount.t(),
          pol_reserve_reward: Amount.t(),
          pool_rewards: [PoolReward.t()]
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(
        %{
          "bond_reward" => bond_reward,
          "dev_fund_reward" => dev_fund_reward,
          "income_burn" => income_burn,
          "tcy_stake_reward" => tcy_stake_reward,
          "marketing_fund_reward" => marketing_fund_reward,
          "pol_reserve_reward" => pol_reserve_reward
        } = attrs
      ) do
    with {:ok, bond_reward} <- Amount.new(bond_reward),
         {:ok, dev_fund_reward} <- Amount.new(dev_fund_reward),
         {:ok, income_burn} <- Amount.new(income_burn),
         {:ok, tcy_stake_reward} <- Amount.new(tcy_stake_reward),
         {:ok, marketing_fund_reward} <- Amount.new(marketing_fund_reward),
         {:ok, pol_reserve_reward} <- Amount.new(pol_reserve_reward),
         {:ok, pool_rewards} <- pool_rewards(attrs) do
      {:ok,
       %__MODULE__{
         bond_reward: bond_reward,
         dev_fund_reward: dev_fund_reward,
         income_burn: income_burn,
         tcy_stake_reward: tcy_stake_reward,
         marketing_fund_reward: marketing_fund_reward,
         pol_reserve_reward: pol_reserve_reward,
         pool_rewards: pool_rewards
       }}
    end
  end

  def new(_), do: {:error, :invalid_attrs}

  # Per-pool rewards are emitted with the asset string as the attribute key and
  # a signed integer value. Keep the attributes whose key resolves to an asset.
  defp pool_rewards(attrs) do
    attrs
    |> Enum.reduce_while({:ok, []}, fn {denom, amount}, {:ok, acc} ->
      case Assets.from_denom(denom) do
        {:ok, asset} ->
          case Math.to_integer(amount) do
            {:ok, amount} -> {:cont, {:ok, [%PoolReward{asset: asset, amount: amount} | acc]}}
            {:error, _} = err -> {:halt, err}
          end

        {:error, _} ->
          {:cont, {:ok, acc}}
      end
    end)
    |> case do
      {:ok, list} -> {:ok, Enum.sort_by(list, & &1.asset.id)}
      err -> err
    end
  end
end
