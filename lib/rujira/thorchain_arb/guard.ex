defmodule Rujira.ThorchainArb.Guard do
  @moduledoc """
  A rujira-thorchain-arb guard contract.

  Struct, construction, and queries. Use `Rujira.ThorchainArb` as the public API.

  The config is the contract's `InstantiateMsg`, mapped exactly as the
  contract defines it: `markets` and `denoms` stay raw strings, so a denom
  rujira_ex has no asset for never fails the read, and `fee` is split from
  its `(Decimal, address)` tuple into `fee` and `fee_address`.

  | Contract                 | Upstream                      | `prepared_fin_checksum`         |
  | ------------------------ | ----------------------------- | ------------------------------- |
  | v0.1.0 (`feat/optimize`) | `2b8b518`, checksum `c4310fe` | decoded bytes, `nil` if omitted |

  The contract omits `prepared_fin_checksum` when it is unset, so a config
  from before `c4310fe` and one without a checksum are the same shape.

  `Rujira.Contracts.version/2` reads the contract version itself.
  """

  alias Rujira.Cache
  alias Rujira.Contracts
  alias Rujira.Deployments
  alias Rujira.Math
  alias Rujira.Node

  # --- Struct ---

  defstruct id: nil,
            address: nil,
            markets: [],
            denoms: [],
            max_queue: 0,
            max_offer_bps: 0,
            reserve_fee: Decimal.new(0),
            fee: Decimal.new(0),
            fee_address: nil,
            chain_defaults: %{},
            prepared_fin_checksum: nil

  @type t :: %__MODULE__{
          id: String.t() | nil,
          address: String.t() | nil,
          markets: [String.t()],
          denoms: [String.t()],
          max_queue: non_neg_integer(),
          max_offer_bps: non_neg_integer(),
          reserve_fee: Decimal.t(),
          fee: Decimal.t(),
          fee_address: String.t() | nil,
          chain_defaults: %{String.t() => integer()},
          prepared_fin_checksum: binary() | nil
        }

  # --- Construction ---

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(
        %{
          "address" => address,
          "markets" => markets,
          "denoms" => denoms,
          "max_queue" => max_queue,
          "max_offer_bps" => max_offer_bps,
          "reserve_fee" => reserve_fee,
          "fee" => [fee, fee_address],
          "chain_defaults" => chain_defaults
        } = attrs
      )
      when is_list(markets) and is_list(denoms) and is_integer(max_queue) and
             is_integer(max_offer_bps) and is_binary(fee_address) and is_map(chain_defaults) do
    with :ok <- strings(markets),
         :ok <- strings(denoms),
         :ok <- chain_defaults(chain_defaults),
         {:ok, reserve_fee} <- Math.to_decimal(reserve_fee),
         {:ok, fee} <- Math.to_decimal(fee),
         {:ok, checksum} <- checksum(Map.get(attrs, "prepared_fin_checksum")) do
      {:ok,
       %__MODULE__{
         id: address,
         address: address,
         markets: markets,
         denoms: denoms,
         max_queue: max_queue,
         max_offer_bps: max_offer_bps,
         reserve_fee: reserve_fee,
         fee: fee,
         fee_address: fee_address,
         chain_defaults: chain_defaults,
         prepared_fin_checksum: checksum
       }}
    end
  end

  def new(_), do: {:error, :invalid_attrs}

  # --- Queries ---

  @spec get(String.t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def get(address, opts \\ []), do: Contracts.get({__MODULE__, address}, opts)

  @doc """
  Lists every deployed arb guard. Fails as a whole when one guard fails.

  Each guard is read concurrently; `opts[:fan_out]` sets the per-guard
  timeout and how many run at once - see `Rujira.Enum`.
  """
  @spec list(Node.opts()) :: {:ok, [t()]} | {:error, term()}
  def list(opts \\ []) do
    with {:ok, opts} <- Cache.pin(opts),
         {:ok, targets} <- Deployments.list_targets(__MODULE__, opts) do
      Rujira.Enum.reduce_async_while_ok(
        targets,
        fn %{address: address} -> Contracts.get({__MODULE__, address}, opts) end,
        opts,
        __MODULE__
      )
    end
  end

  @doc "Resolves a guard by its `id`, which is its contract address. Round-trips."
  @spec from_id(String.t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def from_id(address, opts \\ []), do: get(address, opts)

  # --- Private ---

  defp strings(list) do
    if Enum.all?(list, &is_binary/1), do: :ok, else: {:error, :invalid_attrs}
  end

  defp chain_defaults(map) do
    if Enum.all?(map, fn {_key, value} -> is_integer(value) end),
      do: :ok,
      else: {:error, :invalid_attrs}
  end

  defp checksum(nil), do: {:ok, nil}

  defp checksum(encoded) when is_binary(encoded) do
    case Base.decode64(encoded) do
      {:ok, bytes} -> {:ok, bytes}
      :error -> {:error, :invalid_checksum}
    end
  end

  defp checksum(_), do: {:error, :invalid_checksum}
end
