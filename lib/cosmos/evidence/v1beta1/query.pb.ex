defmodule Cosmos.Evidence.V1beta1.QueryEvidenceRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:evidence_hash, 1, type: :bytes, json_name: "evidenceHash", deprecated: true)
  field(:hash, 2, type: :string)
end

defmodule Cosmos.Evidence.V1beta1.QueryEvidenceResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:evidence, 1, type: Google.Protobuf.Any)
end

defmodule Cosmos.Evidence.V1beta1.QueryAllEvidenceRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pagination, 1, type: Cosmos.Base.Query.V1beta1.PageRequest)
end

defmodule Cosmos.Evidence.V1beta1.QueryAllEvidenceResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:evidence, 1, repeated: true, type: Google.Protobuf.Any)
  field(:pagination, 2, type: Cosmos.Base.Query.V1beta1.PageResponse)
end

defmodule Cosmos.Evidence.V1beta1.Query.Service do
  @moduledoc false

  use GRPC.Service, name: "cosmos.evidence.v1beta1.Query", protoc_gen_elixir_version: "0.13.0"

  rpc(
    :Evidence,
    Cosmos.Evidence.V1beta1.QueryEvidenceRequest,
    Cosmos.Evidence.V1beta1.QueryEvidenceResponse
  )

  rpc(
    :AllEvidence,
    Cosmos.Evidence.V1beta1.QueryAllEvidenceRequest,
    Cosmos.Evidence.V1beta1.QueryAllEvidenceResponse
  )
end

defmodule Cosmos.Evidence.V1beta1.Query.Stub do
  @moduledoc false

  use GRPC.Stub, service: Cosmos.Evidence.V1beta1.Query.Service
end
