defmodule Cosmos.Tx.Config.V1.Config do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:skip_ante_handler, 1, type: :bool, json_name: "skipAnteHandler")
  field(:skip_post_handler, 2, type: :bool, json_name: "skipPostHandler")
end
