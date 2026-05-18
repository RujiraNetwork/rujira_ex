defmodule Thorchain.Types.QueryReferenceMemoRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
  field(:asset, 2, type: :string)
  field(:reference, 3, type: :string)
end

defmodule Thorchain.Types.QueryReferenceMemoResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asset, 1, type: Thorchain.Common.Asset, deprecated: false)
  field(:memo, 2, type: :string)
  field(:reference, 3, type: :string)
  field(:height, 4, type: :int64, deprecated: false)
  field(:registration_hash, 5, type: :string, json_name: "registrationHash", deprecated: false)
  field(:registered_by, 6, type: :bytes, json_name: "registeredBy", deprecated: false)
  field(:used_by_txs, 7, repeated: true, type: :string, json_name: "usedByTxs", deprecated: false)
end

defmodule Thorchain.Types.QueryReferenceMemoByHashRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
  field(:hash, 2, type: :string)
end

defmodule Thorchain.Types.QueryReferenceMemoByHashResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:asset, 1, type: Thorchain.Common.Asset, deprecated: false)
  field(:memo, 2, type: :string)
  field(:reference, 3, type: :string)
  field(:height, 4, type: :int64, deprecated: false)
  field(:registration_hash, 5, type: :string, json_name: "registrationHash", deprecated: false)
  field(:registered_by, 6, type: :bytes, json_name: "registeredBy", deprecated: false)
  field(:used_by_txs, 7, repeated: true, type: :string, json_name: "usedByTxs", deprecated: false)
end

defmodule Thorchain.Types.QueryReferenceMemoPreflightRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
  field(:asset, 2, type: :string)
  field(:amount, 3, type: :string)
end

defmodule Thorchain.Types.QueryReferenceMemoPreflightResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:reference, 1, type: :string)
  field(:available, 2, type: :bool)
  field(:expires_at, 3, type: :int64, json_name: "expiresAt")
  field(:usage_count, 4, type: :int64, json_name: "usageCount")
  field(:max_use, 5, type: :int64, json_name: "maxUse")
  field(:can_register, 6, type: :bool, json_name: "canRegister")
  field(:memo, 7, type: :string)
end
