defmodule Tendermint.Types.Block do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:header, 1, type: Tendermint.Types.Header, deprecated: false)
  field(:data, 2, type: Tendermint.Types.Data, deprecated: false)
  field(:evidence, 3, type: Tendermint.Types.EvidenceList, deprecated: false)
  field(:last_commit, 4, type: Tendermint.Types.Commit, json_name: "lastCommit")
end
