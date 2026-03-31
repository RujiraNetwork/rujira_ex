defmodule Cosmos.Authz.V1beta1.GenericAuthorization do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:msg, 1, type: :string)
end

defmodule Cosmos.Authz.V1beta1.Grant do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:authorization, 1, type: Google.Protobuf.Any, deprecated: false)
  field(:expiration, 2, type: Google.Protobuf.Timestamp, deprecated: false)
end

defmodule Cosmos.Authz.V1beta1.GrantAuthorization do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:granter, 1, type: :string, deprecated: false)
  field(:grantee, 2, type: :string, deprecated: false)
  field(:authorization, 3, type: Google.Protobuf.Any, deprecated: false)
  field(:expiration, 4, type: Google.Protobuf.Timestamp, deprecated: false)
end

defmodule Cosmos.Authz.V1beta1.GrantQueueItem do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:msg_type_urls, 1, repeated: true, type: :string, json_name: "msgTypeUrls")
end
