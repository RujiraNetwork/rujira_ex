defmodule Cosmos.Crypto.Keyring.V1.Record.Local do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:priv_key, 1, type: Google.Protobuf.Any, json_name: "privKey")
end

defmodule Cosmos.Crypto.Keyring.V1.Record.Ledger do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:path, 1, type: Cosmos.Crypto.Hd.V1.BIP44Params)
end

defmodule Cosmos.Crypto.Keyring.V1.Record.Multi do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Crypto.Keyring.V1.Record.Offline do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"
end

defmodule Cosmos.Crypto.Keyring.V1.Record do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  oneof(:item, 0)

  field(:name, 1, type: :string)
  field(:pub_key, 2, type: Google.Protobuf.Any, json_name: "pubKey")
  field(:local, 3, type: Cosmos.Crypto.Keyring.V1.Record.Local, oneof: 0)
  field(:ledger, 4, type: Cosmos.Crypto.Keyring.V1.Record.Ledger, oneof: 0)
  field(:multi, 5, type: Cosmos.Crypto.Keyring.V1.Record.Multi, oneof: 0)
  field(:offline, 6, type: Cosmos.Crypto.Keyring.V1.Record.Offline, oneof: 0)
end
