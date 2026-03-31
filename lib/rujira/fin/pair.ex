defmodule Rujira.Fin.Pair do
  @moduledoc """
  Parses trading pair configuration data into a structured representation for the FIN protocol.
  """
  alias Rujira.Assets
  alias Rujira.Deployments.Target
  alias Rujira.Fin.Book
  alias Rujira.Thorchain.Oracle

  defstruct [
    :id,
    :address,
    :market_makers,
    :token_base,
    :token_quote,
    :oracle_base,
    :oracle_quote,
    :tick,
    :fee_taker,
    :fee_maker,
    :fee_address,
    :book,
    :history,
    :summary,
    :deployment_status
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          address: String.t(),
          market_makers: [String.t()],
          token_base: String.t(),
          token_quote: String.t(),
          oracle_base: Oracle.t() | nil,
          oracle_quote: Oracle.t() | nil,
          tick: integer(),
          fee_taker: Decimal.t(),
          fee_maker: Decimal.t(),
          fee_address: String.t(),
          book: :not_loaded | Book.t(),
          summary: :not_loaded | term(),
          deployment_status: Target.status()
        }

  @spec from_config(String.t(), map()) :: :error | {:ok, __MODULE__.t()}
  def from_config(address, %{"market_maker" => nil} = params) do
    params = params |> Map.delete("market_maker") |> Map.put("market_makers", [])
    from_config(address, params)
  end

  def from_config(address, %{"market_maker" => market_maker} = params) do
    params = params |> Map.delete("market_maker") |> Map.put("market_makers", [market_maker])
    from_config(address, params)
  end

  def from_config(address, %{
        "market_makers" => market_makers,
        "denoms" => denoms,
        "oracles" => oracles,
        "tick" => tick,
        "fee_taker" => fee_taker,
        "fee_maker" => fee_maker,
        "fee_address" => fee_address
      }) do
    with {fee_taker, ""} <- Decimal.parse(fee_taker),
         {fee_maker, ""} <- Decimal.parse(fee_maker),
         {:ok, oracle_base} <- get_oracle(Enum.at(oracles || [], 0)),
         {:ok, oracle_quote} <- get_oracle(Enum.at(oracles || [], 1)) do
      {:ok,
       %__MODULE__{
         id: address,
         address: address,
         market_makers: market_makers,
         token_base: Enum.at(denoms, 0),
         token_quote: Enum.at(denoms, 1),
         oracle_base: oracle_base,
         oracle_quote: oracle_quote,
         tick: tick,
         fee_taker: fee_taker,
         fee_maker: fee_maker,
         fee_address: fee_address,
         book: :not_loaded,
         summary: :not_loaded,
         deployment_status: :live
       }}
    end
  end

  def from_target(%Target{address: address, config: config, status: status}) do
    with %{
           denoms: denoms,
           oracles: oracles,
           market_makers: market_makers,
           tick: tick,
           fee_taker: fee_taker,
           fee_maker: fee_maker,
           fee_address: fee_address
         } <- init_msg(config),
         {fee_taker, ""} <- Decimal.parse(fee_taker),
         {fee_maker, ""} <- Decimal.parse(fee_maker),
         {:ok, oracle_base} <- get_oracle(Enum.at(oracles || [], 0)),
         {:ok, oracle_quote} <- get_oracle(Enum.at(oracles || [], 1)) do
      {:ok,
       %__MODULE__{
         id: address,
         address: address,
         market_makers: market_makers,
         token_base: Enum.at(denoms, 0),
         token_quote: Enum.at(denoms, 1),
         oracle_base: oracle_base,
         oracle_quote: oracle_quote,
         tick: tick,
         fee_taker: fee_taker,
         fee_maker: fee_maker,
         fee_address: fee_address,
         book: :not_loaded,
         summary: :not_loaded,
         deployment_status: status
       }}
    end
  end

  def get_oracle(%{"chain" => chain, "symbol" => symbol}),
    do: get_oracle(%{chain: chain, symbol: symbol})

  def get_oracle(%{chain: chain, symbol: symbol}) do
    id = String.upcase(chain) <> "." <> symbol
    {:ok, %Oracle{id: id, symbol: id, asset: Assets.from_string(id)}}
  end

  def get_oracle(str) when is_binary(str) do
    {:ok, %Oracle{id: String.upcase(str), symbol: String.upcase(str)}}
  end

  def get_oracle(nil), do: {:ok, nil}

  def init_msg(
        %{
          "denoms" => [x, y],
          "fee_address" => fee_address
        } = config
      ) do
    market_makers = Map.get(config, "market_makers")
    tick = Map.get(config, "tick", 6)

    with {:ok, base} <- Assets.from_denom(x),
         {:ok, quote_} <- Assets.from_denom(y) do
      %{
        denoms: [x, y],
        oracles: [
          %{chain: base.chain, symbol: base.symbol},
          %{chain: quote_.chain, symbol: quote_.symbol}
        ],
        market_makers: market_makers,
        tick: tick,
        fee_taker: "0.0015",
        fee_maker: "0.00075",
        fee_address: fee_address
      }
    else
      _ ->
        %{
          denoms: [x, y],
          market_makers: market_makers,
          tick: tick,
          fee_taker: "0.0015",
          fee_maker: "0.00075",
          fee_address: fee_address
        }
    end
  end

  def migrate_msg(_from, _to, _), do: %{}

  def init_label(_, %{"denoms" => [x, y]}), do: "rujira-fin:#{x}:#{y}"
end
