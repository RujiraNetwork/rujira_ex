defmodule Rujira.Fin.Pair.Commit do
  @moduledoc """
  One entry of a FIN pair's `commits` or `arb_commits`: a contract the pair
  calls, and the message it sends it.

  An embedded value struct of `Rujira.Fin.Pair`, with no address of its own to
  read it from, so it has no `id` or `from_id/2`.

  On the wire it is `{addr, msg}`, where `msg` is a CosmWasm `Binary`
  (base64). `msg` holds the decoded bytes; they are not JSON-parsed. A `msg`
  that is not valid base64 is `{:error, :invalid_msg}`; any other shape is
  `{:error, :invalid_attrs}`.
  """

  alias Rujira.String

  defstruct address: nil, msg: nil

  @type t :: %__MODULE__{address: String.t() | nil, msg: binary() | nil}

  @spec new(map()) :: {:ok, t()} | {:error, :invalid_attrs | :invalid_msg}
  def new(%{"addr" => address, "msg" => msg}) when is_binary(address) and is_binary(msg) do
    with {:ok, msg} <- String.decode_base64(msg),
         do: {:ok, %__MODULE__{address: address, msg: msg}}
  end

  def new(_), do: {:error, :invalid_attrs}
end
