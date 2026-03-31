defmodule Cosmos.Tx.Signing.V1beta1.SignMode do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:SIGN_MODE_UNSPECIFIED, 0)
  field(:SIGN_MODE_DIRECT, 1)
  field(:SIGN_MODE_TEXTUAL, 2)
  field(:SIGN_MODE_DIRECT_AUX, 3)
  field(:SIGN_MODE_LEGACY_AMINO_JSON, 127)
  field(:SIGN_MODE_EIP_191, 191)
end

defmodule Cosmos.Tx.Signing.V1beta1.SignatureDescriptors do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:signatures, 1, repeated: true, type: Cosmos.Tx.Signing.V1beta1.SignatureDescriptor)
end

defmodule Cosmos.Tx.Signing.V1beta1.SignatureDescriptor.Data.Single do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:mode, 1, type: Cosmos.Tx.Signing.V1beta1.SignMode, enum: true)
  field(:signature, 2, type: :bytes)
end

defmodule Cosmos.Tx.Signing.V1beta1.SignatureDescriptor.Data.Multi do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:bitarray, 1, type: Cosmos.Crypto.Multisig.V1beta1.CompactBitArray)
  field(:signatures, 2, repeated: true, type: Cosmos.Tx.Signing.V1beta1.SignatureDescriptor.Data)
end

defmodule Cosmos.Tx.Signing.V1beta1.SignatureDescriptor.Data do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  oneof(:sum, 0)

  field(:single, 1, type: Cosmos.Tx.Signing.V1beta1.SignatureDescriptor.Data.Single, oneof: 0)
  field(:multi, 2, type: Cosmos.Tx.Signing.V1beta1.SignatureDescriptor.Data.Multi, oneof: 0)
end

defmodule Cosmos.Tx.Signing.V1beta1.SignatureDescriptor do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field(:public_key, 1, type: Google.Protobuf.Any, json_name: "publicKey")
  field(:data, 2, type: Cosmos.Tx.Signing.V1beta1.SignatureDescriptor.Data)
  field(:sequence, 3, type: :uint64)
end
