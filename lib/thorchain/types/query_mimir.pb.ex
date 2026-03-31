defmodule Thorchain.Types.QueryMimirValuesRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
end

defmodule Thorchain.Types.QueryMimirValuesResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:mimirs, 1, repeated: true, type: Thorchain.Types.Mimir)
end

defmodule Thorchain.Types.QueryMimirWithKeyRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:key, 1, type: :string)
  field(:height, 2, type: :string)
end

defmodule Thorchain.Types.QueryMimirWithKeyResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:value, 1, type: :int64)
end

defmodule Thorchain.Types.QueryMimirAdminValuesRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
end

defmodule Thorchain.Types.QueryMimirAdminValuesResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:admin_mimirs, 1, repeated: true, type: Thorchain.Types.Mimir, json_name: "adminMimirs")
end

defmodule Thorchain.Types.QueryMimirNodesAllValuesRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
end

defmodule Thorchain.Types.QueryMimirNodesAllValuesResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:mimirs, 1, repeated: true, type: Thorchain.Types.NodeMimir, deprecated: false)
end

defmodule Thorchain.Types.QueryMimirNodesValuesRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
end

defmodule Thorchain.Types.QueryMimirNodesValuesResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:mimirs, 1, repeated: true, type: Thorchain.Types.Mimir)
end

defmodule Thorchain.Types.QueryMimirNodeValuesRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string)
  field(:height, 2, type: :string)
end

defmodule Thorchain.Types.QueryMimirNodeValuesResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:node_mimirs, 1, repeated: true, type: Thorchain.Types.Mimir, json_name: "nodeMimirs")
end

defmodule Thorchain.Types.Mimir do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:key, 1, type: :string)
  field(:value, 2, type: :int64)
end
