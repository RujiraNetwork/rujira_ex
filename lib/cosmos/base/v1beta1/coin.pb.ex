defmodule Cosmos.Base.V1beta1.Coin do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:denom, 1, type: :string)
  field(:amount, 2, type: :string, deprecated: false)
end

defmodule Cosmos.Base.V1beta1.DecCoin do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:denom, 1, type: :string)
  field(:amount, 2, type: :string, deprecated: false)
end

defmodule Cosmos.Base.V1beta1.IntProto do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:int, 1, type: :string, deprecated: false)
end

defmodule Cosmos.Base.V1beta1.DecProto do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:dec, 1, type: :string, deprecated: false)
end
