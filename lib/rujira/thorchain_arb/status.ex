defmodule Rujira.ThorchainArb.Status do
  @moduledoc """
  The live status of a rujira-thorchain-arb guard: the pools it has claimed,
  its pending hedges, and whether it is paused.

  Struct, construction, and queries. Use `Rujira.ThorchainArb` as the public API.

  A separate entity from `Rujira.ThorchainArb.Guard`, which is the guard's
  config: the status moves every block, the config only on `update_config`.

  | Contract                 | Upstream  | Shape                                          |
  | ------------------------ | --------- | ---------------------------------------------- |
  | v0.1.0 (`feat/optimize`) | `2b8b518` | `StatusResponse`, unchanged since it was added |

  `height` is the contract's own, as it reports it; `claimed_pools` stay the
  raw pool strings the contract holds.
  """

  alias Rujira.Cache
  alias Rujira.Contracts
  alias Rujira.Node

  # --- Struct ---

  defstruct height: nil, claimed_pools: nil, pending_hedges: nil, paused: nil

  @type t :: %__MODULE__{
          height: non_neg_integer() | nil,
          claimed_pools: [String.t()] | nil,
          pending_hedges: non_neg_integer() | nil,
          paused: boolean() | nil
        }

  # --- Construction ---

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{
        "height" => height,
        "claimed_pools" => claimed_pools,
        "pending_hedges" => pending_hedges,
        "paused" => paused
      })
      when is_integer(height) and is_list(claimed_pools) and is_integer(pending_hedges) and
             is_boolean(paused) do
    with :ok <- pools(claimed_pools) do
      {:ok,
       %__MODULE__{
         height: height,
         claimed_pools: claimed_pools,
         pending_hedges: pending_hedges,
         paused: paused
       }}
    end
  end

  def new(_), do: {:error, :invalid_attrs}

  # --- Queries ---

  @doc """
  A guard's status at `opts[:height]` or the head, cached per block.

  Node errors come back unchanged.
  """
  @spec get(String.t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def get(address, opts \\ []) do
    with {:ok, opts} <- Cache.pin(opts),
         {:ok, res} <- query(address, opts) do
      new(res)
    end
  end

  # --- Private ---

  defp pools([]), do: :ok
  defp pools([pool | rest]) when is_binary(pool), do: pools(rest)
  defp pools(_), do: {:error, :invalid_attrs}

  # The status reports the block it is read in, so it is new every block.
  defp query(address, opts) do
    Cache.fetch({__MODULE__, :query, [address]}, [:per_block], opts, fn _height ->
      Contracts.query_state_smart(address, %{status: %{}}, opts)
    end)
  end
end
