defmodule Rujira.Thorchain.Events do
  @moduledoc """
  Typed event structs and parser for Thorchain native chain events.
  """

  defmodule Swap do
    @moduledoc false
    defstruct [:pool, :id, :coin, :emit_asset, :memo, :from, :to]

    @type t :: %__MODULE__{
            pool: String.t(),
            id: String.t() | nil,
            coin: String.t() | nil,
            emit_asset: String.t() | nil,
            memo: String.t() | nil,
            from: String.t() | nil,
            to: String.t() | nil
          }
  end

  defmodule Transfer do
    @moduledoc false
    defstruct [:sender, :recipient, :amount]
    @type t :: %__MODULE__{sender: String.t(), recipient: String.t(), amount: String.t()}
  end

  defmodule AddLiquidity do
    @moduledoc false
    defstruct [:pool, :rune_address, :asset_address]

    @type t :: %__MODULE__{
            pool: String.t(),
            rune_address: String.t() | nil,
            asset_address: String.t() | nil
          }
  end

  defmodule Withdraw do
    @moduledoc false
    defstruct [:pool]
    @type t :: %__MODULE__{pool: String.t()}
  end

  defmodule PendingLiquidity do
    @moduledoc false
    defstruct [:pool, :rune_address, :asset_address]

    @type t :: %__MODULE__{
            pool: String.t(),
            rune_address: String.t() | nil,
            asset_address: String.t() | nil
          }
  end

  defmodule OraclePrice do
    @moduledoc false
    defstruct [:symbol, :price]
    @type t :: %__MODULE__{symbol: String.t(), price: String.t() | nil}
  end

  defmodule Bond do
    @moduledoc false
    defstruct [:type, :amount, :bond_type]

    @type t :: %__MODULE__{
            type: :bond | :rebond,
            amount: String.t() | nil,
            bond_type: String.t() | nil
          }
  end

  defmodule SetMimir do
    @moduledoc false
    defstruct [:key, :value]
    @type t :: %__MODULE__{key: String.t(), value: String.t() | nil}
  end

  @spec parse(map()) :: struct() | nil

  def parse(%{type: "swap", attributes: %{"pool" => pool} = a}) do
    %Swap{
      pool: pool,
      id: a["id"],
      coin: a["coin"],
      emit_asset: a["emit_asset"],
      memo: a["memo"],
      from: a["from"],
      to: a["to"]
    }
  end

  def parse(%{
        type: "transfer",
        attributes: %{"sender" => sender, "recipient" => recipient, "amount" => amount}
      }) do
    %Transfer{sender: sender, recipient: recipient, amount: amount}
  end

  def parse(%{type: "add_liquidity", attributes: %{"pool" => pool} = a}) do
    %AddLiquidity{pool: pool, rune_address: a["rune_address"], asset_address: a["asset_address"]}
  end

  def parse(%{type: "withdraw", attributes: %{"pool" => pool}}) do
    %Withdraw{pool: pool}
  end

  def parse(%{type: "pending_liquidity", attributes: %{"pool" => pool} = a}) do
    %PendingLiquidity{
      pool: pool,
      rune_address: a["rune_address"],
      asset_address: a["asset_address"]
    }
  end

  def parse(%{type: "oracle_price", attributes: %{"symbol" => symbol} = a}) do
    %OraclePrice{symbol: symbol, price: a["price"]}
  end

  def parse(%{type: "bond" = type, attributes: a}) do
    %Bond{type: String.to_existing_atom(type), amount: a["amount"], bond_type: a["bond_type"]}
  end

  def parse(%{type: "rebond" = type, attributes: a}) do
    %Bond{type: String.to_existing_atom(type), amount: a["amount"], bond_type: a["bond_type"]}
  end

  def parse(%{type: "set_mimir", attributes: %{"key" => key} = a}) do
    %SetMimir{key: key, value: a["value"]}
  end

  def parse(_), do: nil
end
