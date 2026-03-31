defmodule Cosmos.Evidence.V1beta1.MsgSubmitEvidence do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:submitter, 1, type: :string, deprecated: false)
  field(:evidence, 2, type: Google.Protobuf.Any, deprecated: false)
end

defmodule Cosmos.Evidence.V1beta1.MsgSubmitEvidenceResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:hash, 4, type: :bytes)
end

defmodule Cosmos.Evidence.V1beta1.Msg.Service do
  @moduledoc false

  use GRPC.Service, name: "cosmos.evidence.v1beta1.Msg", protoc_gen_elixir_version: "0.13.0"

  rpc(
    :SubmitEvidence,
    Cosmos.Evidence.V1beta1.MsgSubmitEvidence,
    Cosmos.Evidence.V1beta1.MsgSubmitEvidenceResponse
  )
end

defmodule Cosmos.Evidence.V1beta1.Msg.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.Evidence.V1beta1.Msg.Service
end
