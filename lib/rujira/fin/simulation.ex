defmodule Rujira.Fin.Simulation do
  @moduledoc """
  Swap simulation for the FIN protocol.

  Struct, construction, and queries. Use `Rujira.Fin` as the public API.

  `fee` is charged in the same token as `returned` — the token the offer is
  converted into. `rujira-fin`'s `contract.rs` builds both the query response
  (`QueryMsg::Simulate`) and the actual swap's transfer fee from
  `config.denoms.bid(&side)`, i.e. the ask-side token, not the offer token.

  A simulation walks the book, which moves with the oracle and the market makers
  it quotes, so `query/3,4` is cached per `Rujira.Cache` at its own height,
  resolved at `opts[:height]` or - without one - at the head.
  """

  alias Rujira.Amount
  alias Rujira.Assets
  alias Rujira.Assets.Asset
  alias Rujira.Cache
  alias Rujira.Coin
  alias Rujira.Contracts
  alias Rujira.Fin.Pair
  alias Rujira.Math
  alias Rujira.Node

  # --- Struct ---

  defstruct id: nil,
            pair: nil,
            offer: nil,
            returned: nil,
            fee: nil

  @type t :: %__MODULE__{
          id: String.t() | nil,
          pair: String.t() | nil,
          offer: Coin.t() | nil,
          returned: Coin.t() | nil,
          fee: Coin.t() | nil
        }

  # --- Construction ---

  @spec new(map(), map()) :: {:ok, t()} | {:error, term()}
  def new(
        %{pair: pair, offer: %Coin{} = offer, ask: %Asset{} = ask},
        %{"returned" => returned, "fee" => fee}
      ) do
    with {:ok, returned_amount} <- Amount.new(returned),
         {:ok, fee_amount} <- Amount.new(fee) do
      {:ok,
       %__MODULE__{
         pair: pair,
         offer: offer,
         returned: Coin.new(ask, returned_amount),
         fee: Coin.new(ask, fee_amount)
       }}
    end
  end

  def new(_, _), do: {:error, :invalid_attrs}

  # --- Queries ---

  @spec simulate(Pair.t() | String.t(), Coin.t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def simulate(pair, offer, opts \\ [])

  def simulate(
        %Pair{address: address} = pair,
        %Coin{asset: offer_asset, amount: amount} = offer,
        opts
      ) do
    with {:ok, opts} <- Cache.pin(opts),
         {:ok, offer_denom} <- Assets.to_native(offer_asset),
         {:ok, ask} <- ask_asset(pair, offer_denom),
         {:ok, res} <- query(address, offer_asset, amount, opts),
         {:ok, simulation} <- new(%{pair: address, offer: offer, ask: ask}, res) do
      {:ok, %{simulation | id: id(address, offer_denom, amount)}}
    end
  end

  def simulate(address, %Coin{} = offer, opts) when is_binary(address) do
    with {:ok, opts} <- Cache.pin(opts),
         {:ok, pair} <- Pair.get(address, opts) do
      simulate(pair, offer, opts)
    end
  end

  @doc "The contract's answer for swapping `amount` of `asset` on the pair."
  @spec query(String.t(), Asset.t(), non_neg_integer()) :: {:ok, map()} | {:error, term()}
  def query(address, %Asset{} = asset, amount), do: query(address, asset, amount, [])

  @doc """
  As `query/3`, read at `opts[:height]` when given.

  `asset` is resolved to its native denom before the cache is keyed, so two
  assets that name the same denom are the one read.
  """
  @spec query(String.t(), Asset.t(), non_neg_integer(), Node.opts()) ::
          {:ok, map()} | {:error, term()}
  def query(address, %Asset{} = asset, amount, opts) do
    with {:ok, opts} <- Cache.pin(opts),
         {:ok, denom} <- Assets.to_native(asset) do
      Cache.fetch(
        {__MODULE__, :query, [address, denom, amount]},
        [:per_block],
        opts,
        fn _height -> fetch(address, denom, amount, opts) end
      )
    end
  end

  @spec from_id(String.t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def from_id(id, opts \\ []) do
    with [address, denom, amount_str] <- String.split(id, ":"),
         {:ok, amount} when is_integer(amount) <- Math.to_integer(amount_str),
         {:ok, offer} <- Coin.new(denom, amount) do
      simulate(address, offer, opts)
    else
      _ -> {:error, :invalid_id}
    end
  end

  # --- Private ---

  defp fetch(address, denom, amount, opts) do
    Contracts.query_state_smart_with_retry(
      address,
      %{simulate: %{denom: denom, amount: Integer.to_string(amount)}},
      opts
    )
  end

  @spec ask_asset(Pair.t(), String.t()) :: {:ok, Asset.t()} | {:error, :invalid_offer}
  defp ask_asset(%Pair{asset_base: base, asset_quote: quote}, offer_denom) do
    cond do
      Assets.to_native(base) == {:ok, offer_denom} -> {:ok, quote}
      Assets.to_native(quote) == {:ok, offer_denom} -> {:ok, base}
      true -> {:error, :invalid_offer}
    end
  end

  @spec id(String.t(), String.t(), non_neg_integer()) :: String.t()
  defp id(address, denom, amount), do: "#{address}:#{denom}:#{amount}"
end
