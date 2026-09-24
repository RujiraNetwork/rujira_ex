defmodule Rujira.Fin.Simulation do
  @moduledoc """
  Swap simulation for the FIN protocol.

  Struct, construction, and queries. Use `Rujira.Fin` as the public API.

  `fee` is charged in the same token as `returned` — the token the offer is
  converted into. `rujira-fin`'s `contract.rs` builds both the query response
  (`QueryMsg::Simulate`) and the actual swap's transfer fee from
  `config.denoms.bid(&side)`, i.e. the ask-side token, not the offer token.
  """

  alias Rujira.Amount
  alias Rujira.Assets
  alias Rujira.Assets.Asset
  alias Rujira.Coin
  alias Rujira.Contracts
  alias Rujira.Fin.Pair
  alias Rujira.Math

  use Memoize

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

  @spec simulate(Pair.t() | String.t(), Coin.t()) :: {:ok, t()} | {:error, term()}
  def simulate(%Pair{address: address} = pair, %Coin{asset: offer_asset, amount: amount} = offer) do
    with {:ok, offer_denom} <- Assets.to_native(offer_asset),
         {:ok, ask} <- ask_asset(pair, offer_denom),
         {:ok, res} <- query(address, offer_asset, amount),
         {:ok, simulation} <- new(%{pair: address, offer: offer, ask: ask}, res) do
      {:ok, %{simulation | id: id(address, offer_denom, amount)}}
    end
  end

  def simulate(address, %Coin{} = offer) when is_binary(address) do
    with {:ok, pair} <- Pair.get(address) do
      simulate(pair, offer)
    end
  end

  @doc """
  Memoized simulation query.

  Keyed on the typed `(address, asset, amount)` tuple. The native denom is
  resolved from `asset` only here, at the wire boundary.

  Invalidate with `Memoize.invalidate(Rujira.Fin.Simulation, :query, [address, asset, amount])`.
  """
  @spec query(String.t(), Asset.t(), non_neg_integer()) :: {:ok, map()} | {:error, term()}
  defmemo query(address, %Asset{} = asset, amount) do
    with {:ok, denom} <- Assets.to_native(asset) do
      Contracts.query_state_smart_with_retry(address, %{
        simulate: %{denom: denom, amount: Integer.to_string(amount)}
      })
    end
  end

  @spec from_id(String.t()) :: {:ok, t()} | {:error, term()}
  def from_id(id) do
    with [address, denom, amount_str] <- String.split(id, ":"),
         {:ok, amount} when is_integer(amount) <- Math.to_integer(amount_str),
         {:ok, offer} <- Coin.new(denom, amount) do
      simulate(address, offer)
    else
      _ -> {:error, :invalid_id}
    end
  end

  # --- Private ---

  @spec ask_asset(Pair.t(), String.t()) :: {:ok, Asset.t()} | {:error, :invalid_offer}
  defp ask_asset(%Pair{token_base: base, token_quote: quote}, offer_denom) do
    case offer_denom do
      ^base -> Assets.from_denom(quote)
      ^quote -> Assets.from_denom(base)
      _ -> {:error, :invalid_offer}
    end
  end

  @spec id(String.t(), String.t(), non_neg_integer()) :: String.t()
  defp id(address, denom, amount), do: "#{address}:#{denom}:#{amount}"
end
