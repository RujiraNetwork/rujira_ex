defmodule Cosmos.Nft.V1beta1.EventSend do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:class_id, 1, type: :string, json_name: "classId")
  field(:id, 2, type: :string)
  field(:sender, 3, type: :string)
  field(:receiver, 4, type: :string)
end

defmodule Cosmos.Nft.V1beta1.EventMint do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:class_id, 1, type: :string, json_name: "classId")
  field(:id, 2, type: :string)
  field(:owner, 3, type: :string)
end

defmodule Cosmos.Nft.V1beta1.EventBurn do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:class_id, 1, type: :string, json_name: "classId")
  field(:id, 2, type: :string)
  field(:owner, 3, type: :string)
end
