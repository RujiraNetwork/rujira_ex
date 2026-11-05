defmodule Rujira.Ghost.Vault do
  @moduledoc """
  A Ghost money-market vault: a single-denom lending pool that whitelisted
  market contracts borrow from.

  Struct, construction, and queries. Use `Rujira.Ghost` as the public API.

  Parses every `config` shape the contract has served. A vault read at an
  older height serves the shape of the code it ran then. Fields a shape does
  not carry are `nil`:

  | Shape | Upstream (`thorchain/rujira`)              | `config` keys                         | `fee`, `fee_address` |
  | ----- | ------------------------------------------ | ------------------------------------- | -------------------- |
  | V0    | v0.0.1 to v0.1.2 (`787e63b`, Sep 2025)     | no `config` query                     | -                    |
  | V1    | v1.0.0 to v1.0.5 (`355aafa`, Dec 2025)     | `denom`, `interest`                   | `nil`                |
  | V2    | `1303d28` (Feb 2026), v1.0.6 and later     | adds `fee_address`, `fee`             | set                  |

  A V0 vault answers the `config` query with its own parse error, which
  `get/2` returns unchanged and which fails `list/1` as a whole: no vault is
  built from any other read. Unknown extra keys are ignored; a `config` that
  matches no shape is `{:error, :invalid_attrs}`.
  """

  alias Rujira.Assets
  alias Rujira.Assets.Asset
  alias Rujira.Cache
  alias Rujira.Contracts
  alias Rujira.Deployments
  alias Rujira.Ghost.Vault.Interest
  alias Rujira.Ghost.Vault.Status
  alias Rujira.Math
  alias Rujira.Node

  # --- Struct ---

  defstruct id: nil,
            address: nil,
            asset: nil,
            receipt_asset: nil,
            interest: nil,
            fee: nil,
            fee_address: nil,
            status: :not_loaded

  @type t :: %__MODULE__{
          id: String.t() | nil,
          address: String.t() | nil,
          asset: Asset.t() | nil,
          receipt_asset: Asset.t() | nil,
          interest: Interest.t() | nil,
          fee: Decimal.t() | nil,
          fee_address: String.t() | nil,
          status: :not_loaded | Status.t()
        }

  # --- Construction ---

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(%{"fee" => fee, "fee_address" => fee_address} = attrs) do
    with {:ok, fee} <- Math.to_decimal(fee),
         {:ok, vault} <- build(attrs) do
      {:ok, %{vault | fee: fee, fee_address: fee_address}}
    end
  end

  def new(attrs) when not is_map_key(attrs, "fee") and not is_map_key(attrs, "fee_address"),
    do: build(attrs)

  def new(_), do: {:error, :invalid_attrs}

  # The keys every shape that has a `config` query carries.
  defp build(%{"address" => address, "denom" => denom, "interest" => interest}) do
    with {:ok, asset} <- Assets.from_denom(denom),
         {:ok, receipt_asset} <- Assets.from_denom("x/ghost-vault/#{denom}"),
         {:ok, interest} <- Interest.new(interest) do
      {:ok,
       %__MODULE__{
         id: address,
         address: address,
         asset: asset,
         receipt_asset: receipt_asset,
         interest: interest
       }}
    end
  end

  defp build(_), do: {:error, :invalid_attrs}

  # --- Queries ---

  @spec get(String.t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def get(address, opts \\ []), do: Contracts.get({__MODULE__, address}, opts)

  @doc "A vault's id is its address, so this is `get/2`."
  @spec from_id(String.t(), Node.opts()) :: {:ok, t()} | {:error, term()}
  def from_id(id, opts \\ []), do: get(id, opts)

  @doc """
  Lists every deployed vault.

  Each vault is read concurrently; `opts[:fan_out]` sets the per-vault timeout
  and how many run at once - see `Rujira.Enum`.
  """
  @spec list(Node.opts()) :: {:ok, [t()]} | {:error, term()}
  def list(opts \\ []) do
    with {:ok, opts} <- Cache.pin(opts),
         {:ok, targets} <- Deployments.list_targets(__MODULE__, opts) do
      Rujira.Enum.reduce_async_while_ok(
        targets,
        fn %{address: address} -> Contracts.get({__MODULE__, address}, opts) end,
        opts,
        __MODULE__
      )
    end
  end
end
