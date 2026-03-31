defmodule Rujira.Thorchain.Events.Swap do
  @moduledoc "A THORChain pool swap event."

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

  @spec new(map()) :: {:ok, t()}
  def new(%{"pool" => pool} = attrs) do
    {:ok,
     %__MODULE__{
       pool: pool,
       id: Map.get(attrs, "id"),
       coin: Map.get(attrs, "coin"),
       emit_asset: Map.get(attrs, "emit_asset"),
       memo: Map.get(attrs, "memo"),
       from: Map.get(attrs, "from"),
       to: Map.get(attrs, "to")
     }}
  end
end
