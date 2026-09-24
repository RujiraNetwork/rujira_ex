defmodule Rujira.Brune.State do
  @moduledoc """
  Live state of a rujira-brune pool: minted supply, the aggregated node set,
  and pending/collected revenue.

  Struct, construction, and queries. Use `Rujira.Brune` as the public API.
  """

  alias Rujira.Amount
  alias Rujira.Brune.Node
  alias Rujira.Brune.Pool
  alias Rujira.Contracts
  alias Rujira.Math

  use Memoize

  defmodule Nodes do
    @moduledoc "Aggregate bond, weight and capacity across a pool's node set."
    defstruct bond: 0, weight: Decimal.new(0), capacity: 0, nodes: []

    @type t :: %__MODULE__{
            bond: Rujira.Amount.t(),
            weight: Decimal.t(),
            capacity: Rujira.Amount.t(),
            nodes: [Node.t()]
          }
  end

  defmodule Revenue do
    @moduledoc "Pending and collected revenue awaiting distribution to nodes."
    defstruct pending: 0, fee_rate: Decimal.new(0), timestamp: nil

    @type t :: %__MODULE__{
            pending: Rujira.Amount.t(),
            fee_rate: Decimal.t(),
            timestamp: DateTime.t() | nil
          }
  end

  # --- Struct ---

  defstruct minted: 0, nodes: nil, revenue: nil

  @type t :: %__MODULE__{
          minted: Amount.t(),
          nodes: Nodes.t() | nil,
          revenue: Revenue.t() | nil
        }

  # --- Construction ---

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"minted" => minted, "nodes" => nodes, "revenue" => revenue}) do
    with {:ok, minted} <- Amount.new(minted),
         {:ok, nodes} <- nodes(nodes),
         {:ok, revenue} <- revenue(revenue) do
      {:ok, %__MODULE__{minted: minted, nodes: nodes, revenue: revenue}}
    end
  end

  def new(_), do: {:error, :invalid_attrs}

  # --- Queries ---

  @doc "Loads the pool's live state into its `state` field."
  @spec load(Pool.t()) :: {:ok, Pool.t()} | {:error, term()}
  def load(%Pool{address: address} = pool) do
    with {:ok, res} <- query(address),
         {:ok, state} <- new(res) do
      {:ok, %{pool | state: state}}
    end
  end

  @doc """
  Memoized fetch of a pool's live state.

  Invalidate with `Memoize.invalidate(Rujira.Brune.State, :query, [address])`.
  """
  @spec query(String.t()) :: {:ok, map()} | {:error, term()}
  defmemo query(address) do
    Contracts.query_state_smart(address, %{state: %{}})
  end

  # --- Private ---

  defp nodes(%{"bond" => bond, "weight" => weight, "capacity" => capacity, "nodes" => nodes}) do
    with {:ok, bond} <- Amount.new(bond),
         {:ok, weight} <- Math.to_decimal(weight),
         {:ok, capacity} <- Amount.new(capacity),
         {:ok, nodes} <- Rujira.Enum.reduce_while_ok(nodes, &Node.new/1) do
      {:ok, %Nodes{bond: bond, weight: weight, capacity: capacity, nodes: nodes}}
    end
  end

  defp nodes(_), do: {:error, :invalid_attrs}

  defp revenue(%{"pending" => pending, "fee_rate" => fee_rate, "timestamp" => timestamp}) do
    with {:ok, pending} <- Amount.new(pending),
         {:ok, fee_rate} <- Math.to_decimal(fee_rate),
         {:ok, timestamp} <- Math.to_integer(timestamp),
         {:ok, timestamp} <- DateTime.from_unix(timestamp, :nanosecond) do
      {:ok, %Revenue{pending: pending, fee_rate: fee_rate, timestamp: timestamp}}
    end
  end

  defp revenue(_), do: {:error, :invalid_attrs}
end
