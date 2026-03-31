defmodule Cosmos.Autocli.V1.ModuleOptions do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:tx, 1, type: Cosmos.Autocli.V1.ServiceCommandDescriptor)
  field(:query, 2, type: Cosmos.Autocli.V1.ServiceCommandDescriptor)
end

defmodule Cosmos.Autocli.V1.ServiceCommandDescriptor.SubCommandsEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:key, 1, type: :string)
  field(:value, 2, type: Cosmos.Autocli.V1.ServiceCommandDescriptor)
end

defmodule Cosmos.Autocli.V1.ServiceCommandDescriptor do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:service, 1, type: :string)

  field(:rpc_command_options, 2,
    repeated: true,
    type: Cosmos.Autocli.V1.RpcCommandOptions,
    json_name: "rpcCommandOptions"
  )

  field(:sub_commands, 3,
    repeated: true,
    type: Cosmos.Autocli.V1.ServiceCommandDescriptor.SubCommandsEntry,
    json_name: "subCommands",
    map: true
  )
end

defmodule Cosmos.Autocli.V1.RpcCommandOptions.FlagOptionsEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:key, 1, type: :string)
  field(:value, 2, type: Cosmos.Autocli.V1.FlagOptions)
end

defmodule Cosmos.Autocli.V1.RpcCommandOptions do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:rpc_method, 1, type: :string, json_name: "rpcMethod")
  field(:use, 2, type: :string)
  field(:long, 3, type: :string)
  field(:short, 4, type: :string)
  field(:example, 5, type: :string)
  field(:alias, 6, repeated: true, type: :string)
  field(:suggest_for, 7, repeated: true, type: :string, json_name: "suggestFor")
  field(:deprecated, 8, type: :string)
  field(:version, 9, type: :string)

  field(:flag_options, 10,
    repeated: true,
    type: Cosmos.Autocli.V1.RpcCommandOptions.FlagOptionsEntry,
    json_name: "flagOptions",
    map: true
  )

  field(:positional_args, 11,
    repeated: true,
    type: Cosmos.Autocli.V1.PositionalArgDescriptor,
    json_name: "positionalArgs"
  )

  field(:skip, 12, type: :bool)
end

defmodule Cosmos.Autocli.V1.FlagOptions do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:name, 1, type: :string)
  field(:shorthand, 2, type: :string)
  field(:usage, 3, type: :string)
  field(:default_value, 4, type: :string, json_name: "defaultValue")
  field(:deprecated, 6, type: :string)
  field(:shorthand_deprecated, 7, type: :string, json_name: "shorthandDeprecated")
  field(:hidden, 8, type: :bool)
end

defmodule Cosmos.Autocli.V1.PositionalArgDescriptor do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:proto_field, 1, type: :string, json_name: "protoField")
  field(:varargs, 2, type: :bool)
end
