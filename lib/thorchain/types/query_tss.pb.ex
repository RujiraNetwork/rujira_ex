defmodule Thorchain.Types.QueryTssKeygenMetricRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pub_key, 1, type: :string, json_name: "pubKey")
  field(:height, 2, type: :string)
end

defmodule Thorchain.Types.QueryTssKeygenMetricResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:metrics, 1, repeated: true, type: Thorchain.Types.TssKeygenMetric)
end

defmodule Thorchain.Types.QueryTssMetricRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
end

defmodule Thorchain.Types.QueryTssMetricResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:keygen, 1, repeated: true, type: Thorchain.Types.TssKeygenMetric, deprecated: false)
  field(:keysign, 2, type: Thorchain.Types.TssKeysignMetric, deprecated: false)
end
