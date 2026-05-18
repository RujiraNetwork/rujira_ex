defmodule Thorchain.Types.QueryDynamicL1FeesRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
end

defmodule Thorchain.Types.DynamicL1FeeEntry do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:thorname, 1, type: :string)
  field(:pair, 2, type: :string)
  field(:dynamic_bps, 3, type: :uint64, json_name: "dynamicBps")
  field(:whitelist_state, 4, type: :int64, json_name: "whitelistState")
  field(:last_active_epoch, 5, type: :uint64, json_name: "lastActiveEpoch")
  field(:latest_fees_tor, 6, type: :string, json_name: "latestFeesTor")
end

defmodule Thorchain.Types.QueryDynamicL1FeesResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:entries, 1, repeated: true, type: Thorchain.Types.DynamicL1FeeEntry, deprecated: false)
end

defmodule Thorchain.Types.QueryDynamicL1FeesByThornameRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:thorname, 1, type: :string)
  field(:height, 2, type: :string)
end

defmodule Thorchain.Types.DynamicL1FeePairDetail do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:pair, 1, type: :string)
  field(:dynamic_bps, 2, type: :uint64, json_name: "dynamicBps")
  field(:last_active_epoch, 3, type: :uint64, json_name: "lastActiveEpoch")

  field(:history, 4,
    repeated: true,
    type: Thorchain.Types.DynamicL1FeeHistoryEntry,
    deprecated: false
  )
end

defmodule Thorchain.Types.DynamicL1FeeHistoryEntry do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:epoch, 1, type: :uint64)
  field(:volume_tor, 2, type: :string, json_name: "volumeTor")
  field(:fees_tor, 3, type: :string, json_name: "feesTor")
  field(:bps_at_close, 4, type: :uint64, json_name: "bpsAtClose")
end

defmodule Thorchain.Types.QueryDynamicL1FeesByThornameResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:thorname, 1, type: :string)
  field(:whitelist_state, 2, type: :int64, json_name: "whitelistState")

  field(:pairs, 3,
    repeated: true,
    type: Thorchain.Types.DynamicL1FeePairDetail,
    deprecated: false
  )
end

defmodule Thorchain.Types.QueryDynamicL1FeesCurrentRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:height, 1, type: :string)
end

defmodule Thorchain.Types.DynamicL1FeeCurrentEntry do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:thorname, 1, type: :string)
  field(:pair, 2, type: :string)
  field(:volume_tor, 3, type: :string, json_name: "volumeTor")
  field(:fees_tor, 4, type: :string, json_name: "feesTor")
  field(:epoch, 5, type: :uint64)
end

defmodule Thorchain.Types.QueryDynamicL1FeesCurrentResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:epoch, 1, type: :uint64)

  field(:entries, 2,
    repeated: true,
    type: Thorchain.Types.DynamicL1FeeCurrentEntry,
    deprecated: false
  )
end
