defmodule Thorchain.Types.QueryEip712TypedDataRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:sign_bytes, 1, type: :bytes, json_name: "signBytes", deprecated: false)
end

defmodule Thorchain.Types.QueryEip712TypedDataResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:typed_data, 1, type: :string, json_name: "typedData", deprecated: false)
end
