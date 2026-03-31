defmodule Cosmos.Tx.V1beta1.Tx do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:body, 1, type: Cosmos.Tx.V1beta1.TxBody)
  field(:auth_info, 2, type: Cosmos.Tx.V1beta1.AuthInfo, json_name: "authInfo")
  field(:signatures, 3, repeated: true, type: :bytes)
end

defmodule Cosmos.Tx.V1beta1.TxRaw do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:body_bytes, 1, type: :bytes, json_name: "bodyBytes")
  field(:auth_info_bytes, 2, type: :bytes, json_name: "authInfoBytes")
  field(:signatures, 3, repeated: true, type: :bytes)
end

defmodule Cosmos.Tx.V1beta1.SignDoc do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:body_bytes, 1, type: :bytes, json_name: "bodyBytes")
  field(:auth_info_bytes, 2, type: :bytes, json_name: "authInfoBytes")
  field(:chain_id, 3, type: :string, json_name: "chainId")
  field(:account_number, 4, type: :uint64, json_name: "accountNumber")
end

defmodule Cosmos.Tx.V1beta1.SignDocDirectAux do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:body_bytes, 1, type: :bytes, json_name: "bodyBytes")
  field(:public_key, 2, type: Google.Protobuf.Any, json_name: "publicKey")
  field(:chain_id, 3, type: :string, json_name: "chainId")
  field(:account_number, 4, type: :uint64, json_name: "accountNumber")
  field(:sequence, 5, type: :uint64)
  field(:tip, 6, type: Cosmos.Tx.V1beta1.Tip, deprecated: true)
end

defmodule Cosmos.Tx.V1beta1.TxBody do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:messages, 1, repeated: true, type: Google.Protobuf.Any)
  field(:memo, 2, type: :string)
  field(:timeout_height, 3, type: :uint64, json_name: "timeoutHeight")

  field(:extension_options, 1023,
    repeated: true,
    type: Google.Protobuf.Any,
    json_name: "extensionOptions"
  )

  field(:non_critical_extension_options, 2047,
    repeated: true,
    type: Google.Protobuf.Any,
    json_name: "nonCriticalExtensionOptions"
  )
end

defmodule Cosmos.Tx.V1beta1.AuthInfo do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:signer_infos, 1,
    repeated: true,
    type: Cosmos.Tx.V1beta1.SignerInfo,
    json_name: "signerInfos"
  )

  field(:fee, 2, type: Cosmos.Tx.V1beta1.Fee)
  field(:tip, 3, type: Cosmos.Tx.V1beta1.Tip, deprecated: true)
end

defmodule Cosmos.Tx.V1beta1.SignerInfo do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:public_key, 1, type: Google.Protobuf.Any, json_name: "publicKey")
  field(:mode_info, 2, type: Cosmos.Tx.V1beta1.ModeInfo, json_name: "modeInfo")
  field(:sequence, 3, type: :uint64)
end

defmodule Cosmos.Tx.V1beta1.ModeInfo.Single do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:mode, 1, type: Cosmos.Tx.Signing.V1beta1.SignMode, enum: true)
end

defmodule Cosmos.Tx.V1beta1.ModeInfo.Multi do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:bitarray, 1, type: Cosmos.Crypto.Multisig.V1beta1.CompactBitArray)
  field(:mode_infos, 2, repeated: true, type: Cosmos.Tx.V1beta1.ModeInfo, json_name: "modeInfos")
end

defmodule Cosmos.Tx.V1beta1.ModeInfo do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  oneof(:sum, 0)

  field(:single, 1, type: Cosmos.Tx.V1beta1.ModeInfo.Single, oneof: 0)
  field(:multi, 2, type: Cosmos.Tx.V1beta1.ModeInfo.Multi, oneof: 0)
end

defmodule Cosmos.Tx.V1beta1.Fee do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:amount, 1, repeated: true, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
  field(:gas_limit, 2, type: :uint64, json_name: "gasLimit")
  field(:payer, 3, type: :string, deprecated: false)
  field(:granter, 4, type: :string, deprecated: false)
end

defmodule Cosmos.Tx.V1beta1.Tip do
  @moduledoc false

  use Protobuf, deprecated: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:amount, 1, repeated: true, type: Cosmos.Base.V1beta1.Coin, deprecated: false)
  field(:tipper, 2, type: :string, deprecated: false)
end

defmodule Cosmos.Tx.V1beta1.AuxSignerData do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:address, 1, type: :string, deprecated: false)
  field(:sign_doc, 2, type: Cosmos.Tx.V1beta1.SignDocDirectAux, json_name: "signDoc")
  field(:mode, 3, type: Cosmos.Tx.Signing.V1beta1.SignMode, enum: true)
  field(:sig, 4, type: :bytes)
end
