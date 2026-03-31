defmodule Thorchain.Types.QueryRunePoolRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
end

defmodule Thorchain.Types.QueryRunePoolResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pol, 1, type: Thorchain.Types.POL, deprecated: false)
  field(:providers, 2, type: Thorchain.Types.RunePoolProviders, deprecated: false)
  field(:reserve, 3, type: Thorchain.Types.RunePoolReserve, deprecated: false)
end

defmodule Thorchain.Types.POL do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:rune_deposited, 1, type: :string, json_name: "runeDeposited", deprecated: false)
  field(:rune_withdrawn, 2, type: :string, json_name: "runeWithdrawn", deprecated: false)
  field(:value, 3, type: :string, deprecated: false)
  field(:pnl, 4, type: :string, deprecated: false)
  field(:current_deposit, 5, type: :string, json_name: "currentDeposit", deprecated: false)
end

defmodule Thorchain.Types.RunePoolProviders do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:units, 1, type: :string, deprecated: false)
  field(:pending_units, 2, type: :string, json_name: "pendingUnits", deprecated: false)
  field(:pending_rune, 3, type: :string, json_name: "pendingRune", deprecated: false)
  field(:value, 4, type: :string, deprecated: false)
  field(:pnl, 5, type: :string, deprecated: false)
  field(:current_deposit, 6, type: :string, json_name: "currentDeposit", deprecated: false)
end

defmodule Thorchain.Types.RunePoolReserve do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:units, 1, type: :string, deprecated: false)
  field(:value, 2, type: :string, deprecated: false)
  field(:pnl, 3, type: :string, deprecated: false)
  field(:current_deposit, 4, type: :string, json_name: "currentDeposit", deprecated: false)
end
