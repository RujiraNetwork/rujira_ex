defmodule Thorchain.Types.ProtoInt64 do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:value, 1, type: :int64)
end

defmodule Thorchain.Types.ProtoUint64 do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:value, 1, type: :uint64)
end

defmodule Thorchain.Types.ProtoAccAddress do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:value, 1, type: :bytes, deprecated: false)
end

defmodule Thorchain.Types.ProtoAccAddresses do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:value, 1, repeated: true, type: :bytes, deprecated: false)
end

defmodule Thorchain.Types.ProtoString do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:value, 1, type: :string)
end

defmodule Thorchain.Types.ProtoStrings do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:value, 1, repeated: true, type: :string)
end

defmodule Thorchain.Types.ProtoBools do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:value, 1, repeated: true, type: :bool)
end
