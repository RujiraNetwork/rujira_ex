defmodule Thorchain.Types.RUNEProvider do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:rune_address, 1, type: :bytes, json_name: "runeAddress", deprecated: false)
  field(:deposit_amount, 2, type: :string, json_name: "depositAmount", deprecated: false)
  field(:withdraw_amount, 3, type: :string, json_name: "withdrawAmount", deprecated: false)
  field(:units, 4, type: :string, deprecated: false)
  field(:last_deposit_height, 5, type: :int64, json_name: "lastDepositHeight")
  field(:last_withdraw_height, 6, type: :int64, json_name: "lastWithdrawHeight")
end
