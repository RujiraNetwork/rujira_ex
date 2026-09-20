defmodule Rujira.Thorchain.Mimir do
  @moduledoc """
  A THORChain mimir (governance/config) key-value.

  Struct, construction, and queries. Use `Rujira.Thorchain` as the public API.
  """

  alias Thorchain.Types.Mimir, as: TcMimir
  alias Thorchain.Types.Query.Stub
  alias Thorchain.Types.QueryMimirValuesRequest
  alias Thorchain.Types.QueryMimirValuesResponse

  use Memoize

  # --- Struct ---

  defstruct id: nil, key: nil, value: 0

  @type t :: %__MODULE__{
          id: String.t() | nil,
          key: String.t() | nil,
          value: integer()
        }

  # --- Construction ---

  @spec new(TcMimir.t()) :: {:ok, t()} | {:error, term()}
  def new(%TcMimir{key: key, value: value}),
    do: {:ok, %__MODULE__{id: key, key: key, value: value}}

  def new(_), do: {:error, :invalid_attrs}

  # --- Queries ---

  @doc """
  Memoized list of all mimir values.

  Invalidate with `Memoize.invalidate(Rujira.Thorchain.Mimir, :list)`.
  """
  @spec list() :: {:ok, [t()]} | {:error, term()}
  defmemo list, expires_in: Rujira.cache_ttl() do
    with {:ok, %QueryMimirValuesResponse{mimirs: mimirs}} <-
           Rujira.Node.query(&Stub.mimir_values/2, %QueryMimirValuesRequest{}) do
      Rujira.Enum.reduce_while_ok(mimirs, &new/1)
    end
  end

  @spec from_id(String.t()) :: {:ok, t()} | {:error, term()}
  def from_id(key) do
    with {:ok, mimirs} <- list() do
      case Enum.find(mimirs, &(&1.key == key)) do
        nil -> {:error, :not_found}
        mimir -> {:ok, mimir}
      end
    end
  end

  @doc "Pools with LP deposits paused, derived from the `PAUSELPDEPOSIT-<pool>` mimirs."
  @spec halted_pools() :: {:ok, [String.t()]} | {:error, term()}
  def halted_pools do
    with {:ok, mimirs} <- list() do
      {:ok, mimirs |> Enum.filter(&halted?/1) |> Enum.map(&pool/1)}
    end
  end

  # --- Private ---

  defp halted?(%__MODULE__{key: "PAUSELPDEPOSIT-" <> _, value: 1}), do: true
  defp halted?(_), do: false

  defp pool(%__MODULE__{key: "PAUSELPDEPOSIT-" <> rest}),
    do: String.replace(rest, "-", ".", global: false)
end
