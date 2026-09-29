defmodule Rujira.Thorchain.Block.Messages.ObservedTxQuorum do
  @moduledoc """
  An attested observation (`/types.MsgObservedTxQuorum`).

  The enshrined bifrost injects one of these rather than one observation
  message per validator: a single observed transaction with the signatures that
  attest to it, and an `inbound` flag naming its direction instead of the two
  message types `Rujira.Thorchain.Block.Messages.ObservedTxIn` and
  `ObservedTxOut` use.

  The attestations themselves are consensus plumbing - a public key and a
  signature each, and as many as there are validators - so only `attestations`,
  how many attested, is kept.
  """

  alias Rujira.Thorchain.Block.Messages.ObservedTx

  defstruct inbound: true, tx: nil, attestations: 0, signer: nil

  @type t :: %__MODULE__{
          inbound: boolean(),
          tx: ObservedTx.t() | nil,
          attestations: non_neg_integer(),
          signer: String.t() | nil
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"quoTx" => %{"obsTx" => obs} = quorum} = attrs) do
    with {:ok, tx} <- ObservedTx.new(obs) do
      {:ok,
       %__MODULE__{
         inbound: Map.get(quorum, "inbound") == true,
         tx: tx,
         attestations: count(Map.get(quorum, "attestations")),
         signer: Map.get(attrs, "signer")
       }}
    end
  end

  def new(_attrs), do: {:error, :invalid_attrs}

  defp count(attestations) when is_list(attestations), do: length(attestations)
  defp count(_attestations), do: 0
end
