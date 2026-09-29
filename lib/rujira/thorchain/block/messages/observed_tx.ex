defmodule Rujira.Thorchain.Block.Messages.ObservedTx do
  @moduledoc """
  One layer-1 transaction a validator observed, as an observation message
  carries it.

  The fields are the observation itself: the transaction as it appeared on its
  own chain, the vault key that saw it, `status` - whether the chain has
  finished acting on it - the out-transaction hashes it has settled with so
  far, the aggregator swap it carries (if any) and its slippage limit, and the
  two heights that bound when it counts - `block_height`, the layer-1 height
  it was seen at, and `finalise_height`, the height from which THORChain will
  act on it.

  A validator's signatures and the keysign bookkeeping around them are
  consensus plumbing rather than chain data a consumer reads, so they are not
  kept; `Rujira.Thorchain.Block.Messages.ObservedTxQuorum` keeps only how many
  validators attested.
  """

  alias Rujira.Coin
  alias Rujira.Math
  alias Rujira.String

  defstruct id: nil,
            chain: nil,
            from: nil,
            to: nil,
            coins: [],
            gas: [],
            memo: nil,
            status: :incomplete,
            out_hashes: [],
            observed_pub_key: nil,
            block_height: nil,
            finalise_height: nil,
            aggregator: nil,
            aggregator_target: nil,
            aggregator_target_limit: nil

  @type status :: :incomplete | :done | :reverted

  @type t :: %__MODULE__{
          id: String.t() | nil,
          chain: String.t() | nil,
          from: String.t() | nil,
          to: String.t() | nil,
          coins: [Coin.t()],
          gas: [Coin.t()],
          memo: String.t() | nil,
          status: status(),
          out_hashes: [String.t()],
          observed_pub_key: String.t() | nil,
          block_height: integer() | nil,
          finalise_height: integer() | nil,
          aggregator: String.t() | nil,
          aggregator_target: String.t() | nil,
          aggregator_target_limit: integer() | nil
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"tx" => %{"id" => id} = tx} = attrs) do
    with {:ok, coins} <- Rujira.Enum.reduce_while_ok(List.wrap(Map.get(tx, "coins")), &Coin.new/1),
         {:ok, gas} <- Rujira.Enum.reduce_while_ok(List.wrap(Map.get(tx, "gas")), &Coin.new/1),
         {:ok, status} <- status(Map.get(attrs, "status")),
         {:ok, block_height} <- Math.to_integer(Map.get(attrs, "block_height")),
         {:ok, finalise_height} <- Math.to_integer(Map.get(attrs, "finalise_height")),
         {:ok, aggregator_target_limit} <-
           Math.to_integer(Map.get(attrs, "aggregator_target_limit")) do
      {:ok,
       %__MODULE__{
         id: id,
         chain: String.nil_if_empty(Map.get(tx, "chain")),
         from: String.nil_if_empty(Map.get(tx, "from_address")),
         to: String.nil_if_empty(Map.get(tx, "to_address")),
         coins: coins,
         gas: gas,
         memo: String.nil_if_empty(Map.get(tx, "memo")),
         status: status,
         out_hashes: List.wrap(Map.get(attrs, "out_hashes")),
         observed_pub_key: String.nil_if_empty(Map.get(attrs, "observed_pub_key")),
         block_height: block_height,
         finalise_height: finalise_height,
         aggregator: String.nil_if_empty(Map.get(attrs, "aggregator")),
         aggregator_target: String.nil_if_empty(Map.get(attrs, "aggregator_target")),
         aggregator_target_limit: aggregator_target_limit
       }}
    end
  end

  def new(_attrs), do: {:error, :invalid_attrs}

  defp status(nil), do: {:ok, :incomplete}
  defp status("incomplete"), do: {:ok, :incomplete}
  defp status("done"), do: {:ok, :done}
  defp status("reverted"), do: {:ok, :reverted}
  defp status(_), do: {:error, :invalid_status}

  @doc "Every observation of a list, or the first error one of them fails with."
  @spec new_list(term()) :: {:ok, [t()]} | {:error, term()}
  def new_list(nil), do: {:ok, []}
  def new_list(txs) when is_list(txs), do: Rujira.Enum.reduce_while_ok(txs, &new/1)
  def new_list(_txs), do: {:error, :invalid_attrs}
end
