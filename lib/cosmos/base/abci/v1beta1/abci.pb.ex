defmodule Cosmos.Base.Abci.V1beta1.TxResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :int64)
  field(:txhash, 2, type: :string, deprecated: false)
  field(:codespace, 3, type: :string)
  field(:code, 4, type: :uint32)
  field(:data, 5, type: :string)
  field(:raw_log, 6, type: :string, json_name: "rawLog")

  field(:logs, 7,
    repeated: true,
    type: Cosmos.Base.Abci.V1beta1.ABCIMessageLog,
    deprecated: false
  )

  field(:info, 8, type: :string)
  field(:gas_wanted, 9, type: :int64, json_name: "gasWanted")
  field(:gas_used, 10, type: :int64, json_name: "gasUsed")
  field(:tx, 11, type: Google.Protobuf.Any)
  field(:timestamp, 12, type: :string)
  field(:events, 13, repeated: true, type: Tendermint.Abci.Event, deprecated: false)
end

defmodule Cosmos.Base.Abci.V1beta1.ABCIMessageLog do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:msg_index, 1, type: :uint32, json_name: "msgIndex", deprecated: false)
  field(:log, 2, type: :string)
  field(:events, 3, repeated: true, type: Cosmos.Base.Abci.V1beta1.StringEvent, deprecated: false)
end

defmodule Cosmos.Base.Abci.V1beta1.StringEvent do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:type, 1, type: :string)

  field(:attributes, 2,
    repeated: true,
    type: Cosmos.Base.Abci.V1beta1.Attribute,
    deprecated: false
  )
end

defmodule Cosmos.Base.Abci.V1beta1.Attribute do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:key, 1, type: :string)
  field(:value, 2, type: :string)
end

defmodule Cosmos.Base.Abci.V1beta1.GasInfo do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:gas_wanted, 1, type: :uint64, json_name: "gasWanted")
  field(:gas_used, 2, type: :uint64, json_name: "gasUsed")
end

defmodule Cosmos.Base.Abci.V1beta1.Result do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:data, 1, type: :bytes, deprecated: true)
  field(:log, 2, type: :string)
  field(:events, 3, repeated: true, type: Tendermint.Abci.Event, deprecated: false)
  field(:msg_responses, 4, repeated: true, type: Google.Protobuf.Any, json_name: "msgResponses")
end

defmodule Cosmos.Base.Abci.V1beta1.SimulationResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:gas_info, 1,
    type: Cosmos.Base.Abci.V1beta1.GasInfo,
    json_name: "gasInfo",
    deprecated: false
  )

  field(:result, 2, type: Cosmos.Base.Abci.V1beta1.Result)
end

defmodule Cosmos.Base.Abci.V1beta1.MsgData do
  @moduledoc false

  use Protobuf, deprecated: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:msg_type, 1, type: :string, json_name: "msgType")
  field(:data, 2, type: :bytes)
end

defmodule Cosmos.Base.Abci.V1beta1.TxMsgData do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:data, 1, repeated: true, type: Cosmos.Base.Abci.V1beta1.MsgData, deprecated: true)
  field(:msg_responses, 2, repeated: true, type: Google.Protobuf.Any, json_name: "msgResponses")
end

defmodule Cosmos.Base.Abci.V1beta1.SearchTxsResult do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:total_count, 1, type: :uint64, json_name: "totalCount")
  field(:count, 2, type: :uint64)
  field(:page_number, 3, type: :uint64, json_name: "pageNumber")
  field(:page_total, 4, type: :uint64, json_name: "pageTotal")
  field(:limit, 5, type: :uint64)
  field(:txs, 6, repeated: true, type: Cosmos.Base.Abci.V1beta1.TxResponse)
end

defmodule Cosmos.Base.Abci.V1beta1.SearchBlocksResult do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:total_count, 1, type: :int64, json_name: "totalCount")
  field(:count, 2, type: :int64)
  field(:page_number, 3, type: :int64, json_name: "pageNumber")
  field(:page_total, 4, type: :int64, json_name: "pageTotal")
  field(:limit, 5, type: :int64)
  field(:blocks, 6, repeated: true, type: Tendermint.Types.Block)
end
