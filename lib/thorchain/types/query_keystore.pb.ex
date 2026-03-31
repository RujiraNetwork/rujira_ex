defmodule Thorchain.Types.QueryKeysignRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
end

defmodule Thorchain.Types.QueryKeysignPubkeyRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
  field(:pub_key, 2, type: :string, json_name: "pubKey")
end

defmodule Thorchain.Types.QueryKeysignResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:keysign, 1, type: Thorchain.Types.TxOut, deprecated: false)
  field(:signature, 2, type: :string, deprecated: false)
end

defmodule Thorchain.Types.QueryKeygenRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
  field(:pub_key, 2, type: :string, json_name: "pubKey")
end

defmodule Thorchain.Types.QueryKeygenResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:keygen_block, 1,
    type: Thorchain.Types.KeygenBlock,
    json_name: "keygenBlock",
    deprecated: false
  )

  field(:signature, 2, type: :string, deprecated: false)
end
