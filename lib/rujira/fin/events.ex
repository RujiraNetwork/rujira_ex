defmodule Rujira.Fin.Events do
  @moduledoc """
  Typed event structs and parser for FIN protocol wasm events.
  """

  defmodule Trade do
    @moduledoc "A FIN trade event (`wasm-rujira-fin/trade`)."
    defstruct [:contract, :side, :price, :rate, :offer, :bid, :ranges]

    @type t :: %__MODULE__{
            contract: String.t(),
            side: String.t(),
            price: String.t(),
            rate: String.t() | nil,
            offer: String.t() | nil,
            bid: String.t() | nil,
            ranges: String.t() | nil
          }
  end

  defmodule Submit do
    @moduledoc "An order submission event (`wasm-rujira-fin/submit`)."
    defstruct [:contract, :side, :price, :owner]

    @type t :: %__MODULE__{
            contract: String.t(),
            side: String.t(),
            price: String.t(),
            owner: String.t()
          }
  end

  defmodule Retract do
    @moduledoc "An order retraction event (`wasm-rujira-fin/retract`)."
    defstruct [:contract, :side, :price, :owner]

    @type t :: %__MODULE__{
            contract: String.t(),
            side: String.t(),
            price: String.t(),
            owner: String.t()
          }
  end

  defmodule RangeCreate do
    @moduledoc "A range creation event (`wasm-rujira-fin/range.create`)."
    defstruct [:contract, :idx, :owner]

    @type t :: %__MODULE__{
            contract: String.t(),
            idx: String.t(),
            owner: String.t()
          }
  end

  defmodule RangeDeposit do
    @moduledoc "A range deposit event (`wasm-rujira-fin/range.deposit`)."
    defstruct [:contract, :idx, :owner]

    @type t :: %__MODULE__{
            contract: String.t(),
            idx: String.t(),
            owner: String.t()
          }
  end

  defmodule RangeWithdraw do
    @moduledoc "A range withdrawal event (`wasm-rujira-fin/range.withdraw`)."
    defstruct [:contract, :idx, :owner]

    @type t :: %__MODULE__{
            contract: String.t(),
            idx: String.t(),
            owner: String.t()
          }
  end

  defmodule RangeClose do
    @moduledoc "A range close event (`wasm-rujira-fin/range.close`)."
    defstruct [:contract, :idx, :owner]

    @type t :: %__MODULE__{
            contract: String.t(),
            idx: String.t(),
            owner: String.t()
          }
  end

  defmodule RangeClaim do
    @moduledoc "A range fee claim event (`wasm-rujira-fin/range.claim`)."
    defstruct [:contract, :idx, :owner]

    @type t :: %__MODULE__{
            contract: String.t(),
            idx: String.t(),
            owner: String.t()
          }
  end

  defmodule RangeFee do
    @moduledoc "A range fee accrual event (`wasm-rujira-fin/range.fee`)."
    defstruct [:contract, :idx]

    @type t :: %__MODULE__{
            contract: String.t(),
            idx: String.t()
          }
  end

  @doc """
  Parses a raw wasm event map into a typed FIN event struct.

  Returns `nil` if the event is not a FIN event.
  """
  @spec parse(map()) :: struct() | nil

  def parse(%{
        type: "wasm-rujira-fin/trade",
        attributes: %{"_contract_address" => contract, "side" => side, "price" => price} = a
      }) do
    %Trade{
      contract: contract,
      side: side,
      price: price,
      rate: a["rate"],
      offer: a["offer"],
      bid: a["bid"],
      ranges: a["ranges"]
    }
  end

  def parse(%{
        type: "wasm-rujira-fin/submit",
        attributes: %{
          "_contract_address" => contract,
          "side" => side,
          "price" => price,
          "owner" => owner
        }
      }) do
    %Submit{contract: contract, side: side, price: price, owner: owner}
  end

  def parse(%{
        type: "wasm-rujira-fin/retract",
        attributes: %{
          "_contract_address" => contract,
          "side" => side,
          "price" => price,
          "owner" => owner
        }
      }) do
    %Retract{contract: contract, side: side, price: price, owner: owner}
  end

  def parse(%{
        type: "wasm-rujira-fin/range.create",
        attributes: %{"_contract_address" => contract, "idx" => idx, "owner" => owner}
      }) do
    %RangeCreate{contract: contract, idx: idx, owner: owner}
  end

  def parse(%{
        type: "wasm-rujira-fin/range.deposit",
        attributes: %{"_contract_address" => contract, "idx" => idx, "owner" => owner}
      }) do
    %RangeDeposit{contract: contract, idx: idx, owner: owner}
  end

  def parse(%{
        type: "wasm-rujira-fin/range.withdraw",
        attributes: %{"_contract_address" => contract, "idx" => idx, "owner" => owner}
      }) do
    %RangeWithdraw{contract: contract, idx: idx, owner: owner}
  end

  def parse(%{
        type: "wasm-rujira-fin/range.close",
        attributes: %{"_contract_address" => contract, "idx" => idx, "owner" => owner}
      }) do
    %RangeClose{contract: contract, idx: idx, owner: owner}
  end

  def parse(%{
        type: "wasm-rujira-fin/range.claim",
        attributes: %{"_contract_address" => contract, "idx" => idx, "owner" => owner}
      }) do
    %RangeClaim{contract: contract, idx: idx, owner: owner}
  end

  def parse(%{
        type: "wasm-rujira-fin/range.fee",
        attributes: %{"_contract_address" => contract, "idx" => idx}
      }) do
    %RangeFee{contract: contract, idx: idx}
  end

  def parse(_), do: nil
end
