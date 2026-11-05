defmodule Rujira.Ghost.Vault.ShapesTest do
  @moduledoc """
  Every shape the vault-side Ghost responses (status, borrower, borrowers,
  delegate, and the credit contract's borrows) have had on mainnet, read
  through the public `Rujira.Ghost` API.

  No archive node is available, so each fixture is built from the upstream
  `contracts/rujira-ghost-vault/schema/rujira-ghost-vault.json` (or
  `contracts/rujira-ghost-credit/schema/rujira-ghost-credit.json`, for
  `borrows`) at the commit named on it, in `gitlab.com/thorchain/rujira`.

  The reads go through `Rujira.Cache`, whose stores and head are global, so
  this case runs sync and starts from an empty cache.
  """
  use Rujira.Test.CacheCase, async: false

  alias Rujira.Assets
  alias Rujira.Ghost
  alias Rujira.Ghost.Credit
  alias Rujira.Ghost.Vault
  alias Rujira.Ghost.Vault.Borrower
  alias Rujira.Ghost.Vault.Delegate
  alias Rujira.Ghost.Vault.Interest
  alias Rujira.Ghost.Vault.Status
  alias Rujira.Test.MockNode

  # --- Borrower ---

  # v0.0.1 (787e63b): `BorrowerResponse { addr, current, limit, shares }`.
  defp borrower_b0 do
    %{"addr" => "thor1b", "limit" => "500", "current" => "100", "shares" => "90"}
  end

  # v0.1.0 to v0.1.2 (1c784ec, 956e2d6, fbf80aa): adds `available`.
  defp borrower_b1, do: Map.put(borrower_b0(), "available", "400")

  # v1.0.0 to v1.0.8 (355aafa .. 9264370): adds `denom`; `shares` a `Uint128`.
  defp borrower_b2, do: Map.put(borrower_b1(), "denom", "btc-btc")

  # v1.1.0 and later (3ee2d68 .. 9bd0700): `shares` becomes a `Decimal`.
  defp borrower_b3, do: Map.put(borrower_b2(), "shares", "90.25")

  describe "vault_borrower/3" do
    test "B0 (v0.0.1): no available and no denom" do
      MockNode.expect(fn %{"borrower" => %{"addr" => "thor1b"}} ->
        MockNode.ok(borrower_b0())
      end)

      assert {:ok,
              %Borrower{
                address: "thor1b",
                asset: nil,
                limit: 500,
                current: 100,
                available: nil,
                shares: shares
              }} = Ghost.vault_borrower("thor1vault", "thor1b")

      assert Decimal.equal?(shares, Decimal.new(90))
    end

    test "B1 (v0.1.x): available, no denom" do
      MockNode.expect(fn %{"borrower" => _} -> MockNode.ok(borrower_b1()) end)

      assert {:ok, %Borrower{asset: nil, limit: 500, current: 100, available: 400}} =
               Ghost.vault_borrower("thor1vault", "thor1b")
    end

    test "B2 (v1.0.x): denom and available, integer shares" do
      MockNode.expect(fn %{"borrower" => _} -> MockNode.ok(borrower_b2()) end)

      assert {:ok, %Borrower{asset: asset, available: 400, shares: shares}} =
               Ghost.vault_borrower("thor1vault", "thor1b")

      assert asset.id == "BTC-BTC"
      assert Decimal.equal?(shares, Decimal.new(90))
    end

    test "B3 (v1.1.0+): decimal shares" do
      MockNode.expect(fn %{"borrower" => _} -> MockNode.ok(borrower_b3()) end)

      assert {:ok, %Borrower{asset: asset, available: 400, shares: shares}} =
               Ghost.vault_borrower("thor1vault", "thor1b")

      assert asset.id == "BTC-BTC"
      assert Decimal.equal?(shares, Decimal.new("90.25"))
    end

    test "an unknown extra key is ignored" do
      MockNode.expect(fn %{"borrower" => _} ->
        MockNode.ok(Map.put(borrower_b3(), "future", "x"))
      end)

      assert {:ok, %Borrower{available: 400}} = Ghost.vault_borrower("thor1vault", "thor1b")
    end

    test "a shape no clause matches is invalid_attrs" do
      # The unreleased 0.0.0 schema (fedd211) had no `shares`.
      MockNode.expect(fn %{"borrower" => _} ->
        MockNode.ok(Map.delete(borrower_b0(), "shares"))
      end)

      assert {:error, :invalid_attrs} = Ghost.vault_borrower("thor1vault", "thor1b")
    end

    test "denom without available matches no shape" do
      MockNode.expect(fn %{"borrower" => _} ->
        MockNode.ok(Map.delete(borrower_b2(), "available"))
      end)

      assert {:error, :invalid_attrs} = Ghost.vault_borrower("thor1vault", "thor1b")
    end
  end

  describe "vault_borrowers/2" do
    for {shape, fun} <- [b0: :borrower_b0, b1: :borrower_b1, b2: :borrower_b2, b3: :borrower_b3] do
      test "lists #{shape} borrowers" do
        entry = unquote(fun)()

        MockNode.expect(fn %{"borrowers" => _} -> MockNode.ok(%{"borrowers" => [entry]}) end)

        assert {:ok, [%Borrower{address: "thor1b", limit: 500, current: 100}]} =
                 Ghost.vault_borrowers("thor1vault")
      end
    end
  end

  # --- Delegate ---

  describe "vault_delegate/4" do
    # `delegate` exists from v1.0.0 (355aafa); its borrower is a B2.
    test "D0 (v1.0.x): integer shares" do
      MockNode.expect(fn %{"delegate" => %{"borrower" => "thor1b", "addr" => "thor1d"}} ->
        MockNode.ok(%{
          "addr" => "thor1d",
          "current" => "50",
          "shares" => "45",
          "borrower" => borrower_b2()
        })
      end)

      assert {:ok,
              %Delegate{
                address: "thor1d",
                current: 50,
                shares: shares,
                borrower: %Borrower{address: "thor1b", available: 400}
              }} = Ghost.vault_delegate("thor1vault", "thor1b", "thor1d")

      assert Decimal.equal?(shares, Decimal.new(45))
    end

    # v1.1.0 and later (3ee2d68): `shares` a `Decimal`, borrower a B3.
    test "D1 (v1.1.0+): decimal shares" do
      MockNode.expect(fn %{"delegate" => _} ->
        MockNode.ok(%{
          "addr" => "thor1d",
          "current" => "50",
          "shares" => "45.5",
          "borrower" => borrower_b3()
        })
      end)

      assert {:ok, %Delegate{shares: shares, borrower: %Borrower{shares: borrower_shares}}} =
               Ghost.vault_delegate("thor1vault", "thor1b", "thor1d")

      assert Decimal.equal?(shares, Decimal.new("45.5"))
      assert Decimal.equal?(borrower_shares, Decimal.new("90.25"))
    end

    test "a shape no clause matches is invalid_attrs" do
      MockNode.expect(fn %{"delegate" => _} ->
        MockNode.ok(%{"addr" => "thor1d", "current" => "50", "borrower" => borrower_b3()})
      end)

      assert {:error, :invalid_attrs} = Ghost.vault_delegate("thor1vault", "thor1b", "thor1d")
    end
  end

  # --- Status ---

  defp pool(shares), do: %{"size" => "1000", "shares" => shares, "ratio" => "1.1"}

  # v1.0.0 to v1.0.8 (355aafa .. 9264370): both pools a `PoolResponse` with
  # `Uint128` shares.
  defp status_s1 do
    %{
      "last_updated" => "1700000000000000000",
      "utilization_ratio" => "0.5",
      "debt_rate" => "0.12",
      "lend_rate" => "0.06",
      "debt_pool" => pool("900"),
      "deposit_pool" => pool("2000")
    }
  end

  # v0.0.1 to v0.1.2 (787e63b .. fbf80aa): as S1, plus the `interest` curve,
  # which moved to `config` in v1.0.0.
  defp status_s0 do
    Map.put(status_s1(), "interest", %{
      "target_utilization" => "0.8",
      "base_rate" => "0.01",
      "step1" => "0.1",
      "step2" => "1"
    })
  end

  # v1.1.0 and later (3ee2d68): the debt pool's `shares` is a `Decimal`.
  defp status_s2, do: Map.put(status_s1(), "debt_pool", pool("900.75"))

  describe "load_vault/2" do
    test "S0 (v0.x): carries the interest curve" do
      MockNode.expect(fn %{"status" => %{}} -> MockNode.ok(status_s0()) end)

      assert {:ok, %Vault{status: %Status{interest: %Interest{} = interest} = status}} =
               Ghost.load_vault(vault())

      assert Decimal.equal?(interest.target_utilization, Decimal.new("0.8"))
      assert Decimal.equal?(interest.step2, Decimal.new(1))
      assert %Status.DebtPool{size: 1000} = status.debt_pool
      assert %Status.DepositPool{shares: 2000} = status.deposit_pool
    end

    test "S1 (v1.0.x): no interest curve" do
      MockNode.expect(fn %{"status" => %{}} -> MockNode.ok(status_s1()) end)

      assert {:ok, %Vault{status: %Status{interest: nil, debt_pool: debt} = status}} =
               Ghost.load_vault(vault())

      assert Decimal.equal?(debt.shares, Decimal.new(900))
      assert Decimal.equal?(status.utilization_ratio, Decimal.new("0.5"))
      assert DateTime.to_unix(status.last_updated, :nanosecond) == 1_700_000_000_000_000_000
    end

    test "S2 (v1.1.0+): decimal debt shares" do
      MockNode.expect(fn %{"status" => %{}} -> MockNode.ok(status_s2()) end)

      assert {:ok, %Vault{status: %Status{interest: nil, debt_pool: debt}}} =
               Ghost.load_vault(vault())

      assert Decimal.equal?(debt.shares, Decimal.new("900.75"))
    end

    test "an unknown extra key is ignored" do
      MockNode.expect(fn %{"status" => %{}} ->
        MockNode.ok(Map.put(status_s2(), "future", "x"))
      end)

      assert {:ok, %Vault{status: %Status{}}} = Ghost.load_vault(vault())
    end

    test "a malformed interest curve is an error" do
      MockNode.expect(fn %{"status" => %{}} ->
        MockNode.ok(Map.put(status_s1(), "interest", %{}))
      end)

      assert {:error, :invalid_attrs} = Ghost.load_vault(vault())
    end

    test "a shape no clause matches is invalid_attrs" do
      MockNode.expect(fn %{"status" => %{}} ->
        MockNode.ok(Map.delete(status_s1(), "lend_rate"))
      end)

      assert {:error, :invalid_attrs} = Ghost.load_vault(vault())
    end
  end

  # --- Borrows ---

  describe "load_credit/2" do
    # `borrows` exists from credit v1.0.0 (355aafa); entries are B2 until
    # 3ee2d68, and B3 from then on.
    for {shape, fun} <- [b2: :borrower_b2, b3: :borrower_b3] do
      test "loads #{shape} borrows" do
        entry = unquote(fun)()

        MockNode.expect(fn %{"borrows" => %{}} -> MockNode.ok(%{"borrowers" => [entry]}) end)

        assert {:ok, %Credit{borrows: [%Borrower{address: "thor1b", available: 400} = b]}} =
                 Ghost.load_credit(%Credit{id: "thor1credit", address: "thor1credit"})

        assert b.asset.id == "BTC-BTC"
      end
    end
  end

  # --- Fixtures ---

  defp vault do
    %Vault{
      id: "thor1vault",
      address: "thor1vault",
      asset: Assets.from_string("BTC-BTC"),
      receipt_asset: Assets.from_string("x/ghost-vault/btc-btc")
    }
  end
end
