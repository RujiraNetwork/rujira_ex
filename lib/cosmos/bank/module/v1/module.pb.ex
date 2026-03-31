defmodule Cosmos.Bank.Module.V1.Module do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:blocked_module_accounts_override, 1,
    repeated: true,
    type: :string,
    json_name: "blockedModuleAccountsOverride"
  )

  field(:authority, 2, type: :string)
  field(:restrictions_order, 3, repeated: true, type: :string, json_name: "restrictionsOrder")
end
