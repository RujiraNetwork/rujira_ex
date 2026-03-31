defmodule Cosmos.Msg.Textual.V1.PbExtension do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.13.0"

  extend(Google.Protobuf.MessageOptions, :expert_custom_renderer, 11_110_009,
    optional: true,
    type: :string,
    json_name: "expertCustomRenderer"
  )
end
