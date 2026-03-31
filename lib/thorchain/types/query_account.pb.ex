defmodule Thorchain.Types.QueryAccountRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string)
  field(:height, 2, type: :string)
end

defmodule Thorchain.Types.QueryAccountResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string)
  field(:pub_key, 2, type: :string, json_name: "pubKey")
  field(:account_number, 3, type: :string, json_name: "accountNumber")
  field(:sequence, 4, type: :string)
end
