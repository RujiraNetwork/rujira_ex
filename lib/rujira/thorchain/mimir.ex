defmodule Rujira.Thorchain.Mimir do
  @moduledoc """
  A THORChain mimir (governance/config) key-value.

  Struct, construction, and queries. Use `Rujira.Thorchain` as the public API.
  """

  alias Rujira.Node
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
    fetch([])
  end

  @doc """
  As `list/0`, read at `opts[:height]` when one is given - a height read is never
  cached. Without a `:height` this is `list/0`, so the other opts are not applied.
  """
  @spec list(Node.opts()) :: {:ok, [t()]} | {:error, term()}
  def list(opts), do: Node.at_height(opts, fn -> fetch(opts) end, &list/0)

  @spec from_id(String.t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def from_id(key, opts \\ []) do
    with {:ok, mimirs} <- list(opts) do
      case Enum.find(mimirs, &(&1.key == key)) do
        nil -> {:error, :not_found}
        mimir -> {:ok, mimir}
      end
    end
  end

  @doc "Pools with LP deposits paused, derived from the `PAUSELPDEPOSIT-<pool>` mimirs."
  @spec halted_pools(Node.opts()) :: {:ok, [String.t()]} | {:error, term()}
  def halted_pools(opts \\ []) do
    with {:ok, mimirs} <- list(opts) do
      {:ok, mimirs |> Enum.filter(&halted?/1) |> Enum.map(&pool/1)}
    end
  end

  # --- Private ---

  defp fetch(opts) do
    with {:ok, %QueryMimirValuesResponse{mimirs: mimirs}} <-
           Node.query(&Stub.mimir_values/3, %QueryMimirValuesRequest{}, opts) do
      Rujira.Enum.reduce_while_ok(mimirs, &new/1)
    end
  end

  defp halted?(%__MODULE__{key: "PAUSELPDEPOSIT-" <> _, value: 1}), do: true
  defp halted?(_), do: false

  defp pool(%__MODULE__{key: "PAUSELPDEPOSIT-" <> rest}),
    do: String.replace(rest, "-", ".", global: false)
end
